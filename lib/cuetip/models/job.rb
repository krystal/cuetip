# frozen_string_literal: true

require 'active_record'
require 'cuetip/models/queued_job'
require 'cuetip/serialized_hashie'

module Cuetip
  module Models
    class Job < ActiveRecord::Base
      self.table_name = 'cuetip_jobs'

      STATUSES = %w[Pending Running Complete Aborted Expired].freeze

      has_one :queued_job, class_name: 'Cuetip::Models::QueuedJob'
      belongs_to :associated_object, polymorphic: true, optional: true

      serialize :params, Cuetip::SerializedHashie

      before_validation(on: :create) do
        self.status = 'Pending'
      end

      after_create do
        # After creation, automatically add this job into the job queue for execution
        create_queued_job!(run_after: run_after || delay_execution&.seconds&.from_now, queue_name: queue_name)
      end

      # Is this job in the queue
      def queued?
        queued_job.present?
      end

      # Has this job expired?
      def expired?
        ttl? ? expires_at <= Time.now : false
      end

      # The time that this job expired
      def expires_at
        ttl? ? created_at + ttl : nil
      end

      # Should this job be requeued on a failure right now?
      def requeue_on_failure?
        retry_count && retry_interval ? executions <= retry_count : false
      end

      # Remove this job from the queue
      def remove_from_queue
        queued_job&.destroy
        self.queued_job = nil
        log 'Removed from queue'
      end

      # Log some text about this job
      #
      # @param text [String]
      def log(text)
        Cuetip.logger.info "[#{id}] #{text}"
      end

      # Execute the job
      #
      # @return [Boolean] whether the job executed successfully or not
      def execute(&block)
        log "Beginning execution of job #{id} with #{class_name}"
        # Initialize a new instance of the job we wish to execute
        job_klass = class_name.constantize.new(self)

        # If the job has expired, we should not be executing this so we'll just
        # remove it from the queue and mark it as expired.
        if expired?
          log 'Job has expired'
          self.status = 'Expired'
          remove_from_queue
          Cuetip.config.emit(:expired, self, job_klass)
          return false
        end

        # If we have a block, call this so we can manipulate our actual job class
        # before execution if needed (mostly for testing)
        block.call(job_klass) if block_given?

        # Mark the job as runnign
        update!(status: 'Running', started_at: Time.now, executions: executions + 1)

        begin
          # Perform the job within a timeout
          Timeout.timeout(maximum_execution_time || 1.year) do
            job_klass.perform
          end
          # Mark the job as complete and remove it from the queue
          self.status = 'Complete'
          log 'Job completed successfully'
          remove_from_queue

          Cuetip.config.emit(:completed, self, job_klass)

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
          if requeue_on_failure?
            # Requeue this job for execution again after the retry interval.
            new_job = queued_job.requeue(run_after: Time.now + retry_interval.to_i)
            log "Requeing job to run after #{new_job.run_after.to_s(:long)}"
            self.status = 'Pending'
          else
            # We're done with this job. We can't do any more retries.
            remove_from_queue
          end

          Cuetip.config.emit(:exception, e, self, job_klass)

          false
        end
      ensure
        self.finished_at = Time.now
        save!
        Cuetip.config.emit(:finished, self, job_klass)
        log 'Finished processing'
      end
    end
  end
end
