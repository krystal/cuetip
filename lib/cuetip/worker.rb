require 'cuetip/models/queued_job'

module Cuetip
  class Worker
    
    attr_reader :status

    include ActiveSupport::Callbacks

    define_callbacks :execute, :poll

    def initialize(group, id)
      @group = group
      @id = id
    end

    def request_exit!
      @exit_requested = true
      interrupt_sleep
    end

    def run
      set_status("idle")
      loop do
        unless run_once
          interruptible_sleep(Cuetip.config.polling_interval + rand)
        end

        if @exit_requested
          break
        end
      end
    end

    def run_once
      set_status("polling")
      run_callbacks :poll do
        if queued_job = Cuetip::Models::QueuedJob.find_and_lock
          set_status("executing #{queued_job.job.id}")
            run_callbacks :execute do
              queued_job.job.execute
            end
          set_status("idle")
          true
        else
          set_status("idle")
          false
        end
      end
    end

    private

    def set_status(status)
      @status = status
      @group.set_process_name if @group
    end

    def interruptible_sleep(seconds)
      @_sleep_check, @_sleep_interrupt = IO.pipe
      IO.select([@_sleep_check], nil, nil, seconds)
    end

    def interrupt_sleep
      @_sleep_interrupt.close if @_sleep_interrupt
    end

  end
end
