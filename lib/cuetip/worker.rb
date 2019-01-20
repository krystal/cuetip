module Cuetip
  class Worker

    attr_accessor :down_pipe
    attr_accessor :up_pipe
    attr_reader :monitor

    def initialize(monitor)
      @monitor = monitor
    end

    # This method runs in a child process
    def run
      while run_once; end
    end

    def run_once
      @up_pipe.puts "READY"
      request = @down_pipe.gets
      if request
        command, *params = request.strip.split(':')
        case command
        when 'run'
          if queued_job = Cuetip::Models::QueuedJob.find_by_id(params[0].to_i)
            process_queued_job(queued_job)
          else
            Cuetip.logger.debug "Queued job #{params[0].to_i} not found."
          end
        when 'exit'
          # Master has requested exit, so exit
          return false
        end
      else
        # Master seems to have gone away, so exit
        return false
      end
      true
    end

    def process_queued_job(queued_job)
      if queued_job.lock!
        Cuetip.logger.debug "Queued job #{queued_job.id} locked."
        Cuetip.logger.debug "Executing job #{queued_job.job_id}."
        queued_job.job.execute
      else
        Cuetip.logger.debug "Queued job #{queued_job.id} locked elsewhere. Skipping."
      end
    end

    def setup_pipes
      @down_pipe, @monitor.down_pipe = IO.pipe
      @monitor.up_pipe, @up_pipe     = IO.pipe
    end

    def start
      setup_pipes
      @monitor.pid = fork do
        @monitor.down_pipe.close
        @monitor.up_pipe.close
        self.run
      end
      @down_pipe.close
      @up_pipe.close
    end

  end
end
