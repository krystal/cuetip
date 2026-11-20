# frozen_string_literal: true

require 'active_job'
require 'active_support/json'
require 'cuetip'
require 'cuetip/active_job_wrapper'

module ActiveJob
  module QueueAdapters
    # Active Job adapter for Cuetip.
    #
    #   config.active_job.queue_adapter = :cuetip
    #
    # Jobs are stored in the cuetip tables and run by the `cuetip` worker.
    # Job priority is not supported and is ignored.
    class CuetipAdapter < AbstractAdapter
      # Cuetip stores jobs in the application's own database, so enqueueing
      # inside a transaction is already atomic: a rolled-back transaction also
      # rolls back the job. Only consulted by Rails 7.2.
      def enqueue_after_transaction_commit?
        false
      end

      def enqueue(job)
        create_cuetip_job(job)
      end

      def enqueue_at(job, timestamp)
        create_cuetip_job(job, run_after: Time.at(timestamp))
      end

      private

      def create_cuetip_job(job, run_after: nil)
        # Stored as a JSON string: Cuetip's params serializer strips blank
        # values, which would corrupt arguments such as nil or "".
        params = {
          'job_class' => job.class.name,
          'job_data' => ActiveSupport::JSON.encode(job.serialize)
        }

        cuetip_job = Cuetip::ActiveJobWrapper.queue(params) do |j|
          j.queue_name = job.queue_name
          j.run_after = run_after
          # Active Job has no expiry, and a job scheduled with `wait:` must not
          # expire before it runs.
          j.ttl = nil
        end

        job.provider_job_id = cuetip_job.id
        cuetip_job
      end
    end
  end
end
