module Cuetip
  class Monitor

    attr_accessor :down_pipe
    attr_accessor :up_pipe
    attr_accessor :pid
    attr_accessor :status

    def initialize(supervisor)
      @supervisor = supervisor
      @status = :starting
    end

    def wait_nonblock
      begin
        @up_pipe.read_nonblock(100)
        @status = :available
        Cuetip.logger.debug "Worker #{self.object_id} ready."
      rescue IO::EAGAINWaitReadable
        # Nothing to do
      rescue EOFError
        # Child exited
        Process.waitpid2(@pid)
        @supervisor.workers.delete(@pid)
        return false
      end
      true
    end

    def run_job(queued_job)
      @down_pipe.puts "run:#{queued_job.id}"
      @status = :busy
    end

    def available?
      @status == :available
    end

  end
end
