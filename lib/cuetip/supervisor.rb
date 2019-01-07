module Cuetip
  class Supervisor

    attr_reader :workers

    def initialize
      @workers = {}
    end

    def run
      loop do
        @workers.values.dup.each do |monitor|
          monitor.wait_nonblock
        end
        puts @workers.inspect
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
      worker = @workers.values.first
      worker.run_job
      true
    end

  end
end
