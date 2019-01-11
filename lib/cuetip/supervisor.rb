module Cuetip
  class Supervisor

    attr_reader :workers

    def initialize
      @workers = {}
    end

    def run
      loop do
        check_workers
        run_job
        sleep 0.5
      end
    end

    def start_worker
      monitor = Monitor.new(self)
      worker = Worker.new(monitor)
      worker.start
      @workers[monitor.pid] = monitor
    end

    def run_job
      Cuetip.logger.debug "Attempting to execute job."
      if w = available_worker
        Cuetip.logger.debug "Executing job on worker #{w.object_id}."
        w.run_job
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
