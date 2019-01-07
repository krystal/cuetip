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
        @down_pipe.gets
        sleep 1
        @up_pipe.puts "DONE"
        Process.exit(0)
      end
    end

    def setup_pipes
      @down_pipe, @monitor.down_pipe = IO.pipe
      @monitor.up_pipe, @up_pipe     = IO.pipe
    end

    def start
      ActiveRecord::Base.clear_all_connections!
      setup_pipes
      @monitor.pid = fork do
        @monitor.down_pipe.close
        @monitor.up_pipe.close
        self.run
      end
      @down_pipe.close
      @up_pipe.close
    end

    def gets
      @down_pipe.gets
    end

    def puts(data)
      @up_pipe.puts(data)
    end

  end
end
