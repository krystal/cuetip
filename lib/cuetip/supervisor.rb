module Cuetip
  class Supervisor

    attr_reader :workers

    def initialize
      @workers = {}
    end

    def run
      loop do
        check_workers
        Cuetip::Models::QueuedJob.pending.each do |qj|
          run_job(qj)
        end

        sleep 1
      end
    end

    def start_worker
      monitor = Monitor.new(self)
      worker = Worker.new(monitor)
      worker.start
      @workers[monitor.pid] = monitor
    end

    def run_job(queued_job)
      Cuetip.logger.debug "Attempting to execute job."
      if monitor = available_worker
        Cuetip.logger.debug "Executing job on worker #{monitor.object_id}."
        monitor.run_job(queued_job)
        true
      else
        Cuetip.logger.debug "No workers available"
        false
      end
    end

    def check_workers
      ## Check for replies from all child wokers
      @workers.values.each do |monitor|
        monitor.wait_nonblock
      end

      ## Ensure we have the appropriate number of workers
      if @workers.size < Cuetip.config.workers
        Cuetip.config.before_fork&.call
        while workers.size < Cuetip.config.workers
          start_worker
        end
        Cuetip.config.after_fork&.call
      end
    end

    def available_worker
      @workers.values.shuffle.find{ | monitor | monitor.available? }
    end

  end
end
