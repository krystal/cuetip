# frozen_string_literal: true

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
      set_status('idle')
      loop do
        unless run_once
          interruptible_sleep(Cuetip.config.polling_interval + rand)
        end

        break if @exit_requested
      end
    end

    def run_once
      set_status('polling')
      run_callbacks :poll do
        queued_job = silence { Cuetip::Models::QueuedJob.find_and_lock }

        if queued_job
          set_status("executing #{queued_job.job.id}")
          run_callbacks :execute do
            queued_job.job.execute
          end
          set_status('idle')
          true
        else
          set_status('idle')
          false
        end
      end
    end

    private

    def set_status(status)
      @status = status
      @group&.set_process_name
    end

    def interruptible_sleep(seconds)
      sleep_check, @sleep_interrupt = IO.pipe
      IO.select([sleep_check], nil, nil, seconds)
      sleep_check.close
      @sleep_interrupt.close
    end

    def interrupt_sleep
      @sleep_interrupt&.close
    end

    def silence(&block)
      if ActiveRecord::Base.logger
        ActiveRecord::Base.logger.silence(&block)
      else
        block.call
      end
    end
  end
end
