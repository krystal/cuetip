module Cuetip
  class Worker

    attr_accessor :exit_now

    def run
      Process.setproctitle("Cuetip: IDLE")
      trap(:TERM) do
        self.exit_now = true
      end

      loop do
        ran = run_once
        sleep(Cuetip.config.polling_interval + rand) unless ran
        Process.exit(0) if self.exit_now
      end
    end

    def run_once
      if queued_job = Cuetip::Models::QueuedJob.find_and_lock
        Process.setproctitle("Cuetip: EXEC #{queued_job.job.id}")
        queued_job.job.execute
        Process.setproctitle("Cuetip: IDLE")
        true
      else
        false
      end
    end

  end
end
