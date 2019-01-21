require 'cuetip/models/queued_job'

module Cuetip
  class Worker

    def initialize(group, id)
      @group = group
      @id = id
    end

    def request_exit!
      @exit_requested = true
    end

    def sleeping?
      @sleeping == true
    end

    def run
      loop do
        @sleeping = false

        unless run_once
          @sleeping = true
          sleep(Cuetip.config.polling_interval + rand)
        end

        if @exit_requested
          break
        end
      end
    end

    def run_once
      if queued_job = Cuetip::Models::QueuedJob.find_and_lock
        queued_job.job.execute
        true
      else
        false
      end
    end

  end
end
