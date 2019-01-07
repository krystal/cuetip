module Cuetip
  class Monitor

    attr_accessor :down_pipe
    attr_accessor :up_pipe
    attr_accessor :pid
    attr_accessor :status

    def wait_nonblock
      begin
        @up_pipe.read_nonblock(100)
        @status = :available
        STDERR.puts "worker ready"
      rescue IO::EAGAINWaitReadable
        # Nothing to do
      end
    end

    def run_job
      @down_pipe.puts "run:1"
      @status = :busy
    end

  end
end
