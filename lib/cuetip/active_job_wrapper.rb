# frozen_string_literal: true

require 'json'
require 'active_job'
require 'cuetip/job'

module Cuetip
  # A Cuetip job that runs an Active Job. Jobs enqueued through the :cuetip
  # Active Job adapter are stored as this class, with the serialized Active Job
  # kept in the `job_data` param.
  class ActiveJobWrapper < Cuetip::Job
    # Active Job handles retries itself (retry_on re-enqueues through the
    # adapter), so Cuetip must not retry on top of it.
    self.retry_count = 0

    def perform
      ::ActiveJob::Base.execute(JSON.parse(params.job_data))
    end
  end
end
