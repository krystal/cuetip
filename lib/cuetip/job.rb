module Cuetip
  class Job

    class << self

      # The queue that this job should be executed on
      def queue_name
        @queue_name || 'default'
      end
      attr_writer :queue_name

      # The maximum length of time (in seconds) that a job can run for
      def maximum_execution_time
        @maximum_execution_time || 12.hours
      end
      attr_writer :maximum_execution_time

      # The maximum length of time (in seconds) between the job being created and it being run
      def ttl
        @ttl || 6.hours
      end
      attr_writer :ttl

      # The maximum number of times this job can be run
      def retry_count
        @retry_count || 0
      end
      attr_writer :retry_count

      # The maximum length of time (in seconds) between each execution of this job
      def retry_interval
        @retry_interval || 1.minute
      end
      attr_writer :retry_interval

      # The length of time (in seconds) from when this job is queued to when it should be executed
      def delay_execution
        @delay_execution || 0
      end
      attr_writer :delay_execution

      # Queue this job
      #
      # @param params [Hash]
      # @return [Cuetip::Models::Job]
      def queue(params = {}, &block)
        # Create our new job
        job = Models::Job.new(:class_name => self.name, :params => params)
        # Copy over any class leve lconfig
        job.queue_name = self.queue_name
        job.maximum_execution_time = self.maximum_execution_time
        job.ttl = self.ttl
        job.retry_count = self.retry_count
        job.retry_interval = self.retry_interval
        job.delay_execution = self.delay_execution
        # Call the block
        block.call(job) if block_given?
        # Create the job
        job.save!
        # Return the job
        job
      end
    end

    # Initialize this job instance by providing a queued job instance
    #
    # @param queued_job [Cuetip::QueuedJob]
    def initialize(queued_job)
      @queued_job = queued_job
    end

    # Perform a job
    #
    # @return [void]
    def perform
    end

    private

    # Return all parameters for the job
    #
    # @return [Hashie::Mash]
    def params
      @queued_job.params
    end

    # Return the queued job object
    #
    # @return [Cuetip::QueuedJob]
    def queued_job
      @queued_job
    end

  end
end
