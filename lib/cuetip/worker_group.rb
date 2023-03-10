# frozen_string_literal: true

require 'cuetip/worker'

module Cuetip
  class WorkerGroup
    include ActiveSupport::Callbacks

    define_callbacks :run_worker

    attr_reader :quantity
    attr_reader :workers
    attr_reader :threads

    def initialize(quantity, queues)
      @quantity = quantity
      @queues = queues || []
      @workers = {}
      @threads = {}
    end

    def start
      Klogger.tagged(pid: Process.pid) do
        Cuetip.logger.info "Starting workers", quantity: @quantity
        if @queues.any?
          @queues.each { |q| Cuetip.logger.info "Joined queue", queue: q }
        end

        exit_trap = proc do
          @workers.each { |_, worker| worker.request_exit! }
          puts 'Exiting...'
        end

        trap('INT', &exit_trap)
        trap('TERM', &exit_trap)

        @quantity.times do |i|
          @workers[i] = Worker.new(self, i, @queues)
          Klogger.tagged worker_index: i do
            Cuetip.logger.info "Starting worker"
            @threads[i] = Thread.new(@workers[i]) do |worker|
              run_callbacks :run_worker do
                worker.run
              end
            end
          end
          @threads[i].abort_on_exception = true
        end
        @threads.values.each(&:join)
      end
    end

    def set_process_name
      thread_names = @workers.values.map(&:status)
      Process.setproctitle("Cuetip: #{thread_names.inspect}")
    end
  end
end
