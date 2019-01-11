module Cuetip
  class Worker

    attr_accessor :down_pipe
    attr_accessor :up_pipe

    def initialize(monitor)
      @monitor = monitor
    end

    # This method runs in a child process
    def run
      loop do
        @up_pipe.puts "READY"
        request = @down_pipe.gets
        if request
          command, *params = request.strip.split(':')
          case command
          when 'run'
            if queued_job = QueuedJob.find_by_id(params[0].to_i)
              sleep 1
            end
          when 'exit'
            # Master has requested exit, so exit
            break
          end
        else
          # Master seems to have gone away, so exit
          break
        end
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
