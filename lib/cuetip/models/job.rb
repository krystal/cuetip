require 'active_record'
require 'cuetip/models/queued_job'
require 'cuetip/serialized_hashie'

module Cuetip
  module Models
    class Job < ActiveRecord::Base

      self.table_name = 'cuetip_jobs'

      STATUSES = ['Pending', 'Running', 'Complete', 'Aborted', 'Expired']

      has_one :queued_job, :class_name => 'Cuetip::Models::QueuedJob'
      belongs_to :associated_object, :polymorphic => true, :optional => true

      serialize :params, Cuetip::SerializedHashie

      before_validation(:on => :create) do
        self.status = 'Pending'
      end

      after_create do
        # After creation, automatically add this job into the job queue for execution
        create_queued_job!(:run_after => self.run_after || self.delay_execution&.seconds&.from_now , :queue_name => self.queue_name)
      end

      # Is this job in the queue
      def queued?
        queued_job.present?
      end

      # Has this job expired?
      def expired?
        self.ttl? ? expires_at <= Time.now : false
      end

      # The time that this job expired
      def expires_at
        self.ttl? ? self.created_at + self.ttl : nil
      end

      # Should this job be requeued on a failure right now?
      def requeue_on_failure?
        self.retry_count && self.retry_interval ? self.executions <= self.retry_count : false
      end

      # Remove this job from the queue
      def remove_from_queue
        self.queued_job&.destroy
        self.queued_job = nil
        log "Removed from queue"
      end

      # Log some text about this job
      #
      # @param text [String]
      def log(text)
        Cuetip.logger.info "[#{self.id}] #{text}"
      end

      # Execute the job
      #
      # @return [Boolean] whether the job executed successfully or not
      def execute(&block)
        log "Beginning execution of job #{self.id} with #{self.class_name}"
        # Initialize a new instance of the job we wish to execute
        job_klass = self.class_name.constantize.new(self)

        # If the job has expired, we should not be executing this so we'll just
        # remove it from the queue and mark it as expired.
        if self.expired?
          log "Job has expired"
          self.status = 'Expired'
          self.remove_from_queue
          return false
        end

        # If we have a block, call this so we can manipulate our actual job class
        # before execution if needed (mostly for testing)
        block.call(job_klass) if block_given?

        # Mark the job as runnign
        self.update!(:status => 'Running', :started_at => Time.now, :executions => self.executions + 1)

        begin
          # Perform the job within a timeout
          Timeout.timeout(self.maximum_execution_time || 1.year) do
            job_klass.perform
          end
          # Mark the job as complete and remove it from the queue
          self.status = 'Complete'
          log "Job completed successfully"
          self.remove_from_queue
          true
        rescue Exception, Timeout::TimeoutError => e
          log "Job failed with #{e.class} (#{e.message})"

          # If there's an error, mark the job as failed and copy exception
          # data into the job
          self.status = 'Failed'
          self.exception_class = e.class.name
          self.exception_message = e.message
          self.exception_backtrace = e.backtrace.join("\n")

          # Handle requeing the job if needed.
          if self.requeue_on_failure?
            # Requeue this job for execution again after the retry interval.
            new_job = self.queued_job.requeue(:run_after => Time.now + self.retry_interval.to_i)
            log "Requeing job to run after #{new_job.run_after.to_s(:long)}"
            self.status = 'Pending'
          else
            # We're done with this job. We can't do any more retries.
            self.remove_from_queue
          end

          false
        end
      ensure
        self.finished_at = Time.now
        self.save!
        log "Finished processing"
      end

    end
  end
end
