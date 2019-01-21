require 'cuetip/worker'

module Cuetip
  class WorkerGroup

    def initialize(quantity)
      @quantity = quantity
      @workers = {}
      @threads = {}
    end

    def start
      Cuetip.logger.info "Starting #{@quantity} Cuetip workers"

      exit_trap = proc do
        @workers.each { |_, worker| worker.request_exit! }
        puts "Exiting..."
      end

      trap('INT', &exit_trap)
      trap('TERM', &exit_trap)

      @quantity.times do |i|
        @workers[i] = Worker.new(self, i)
        Cuetip.logger.info "-> Starting worker #{i}"
        @threads[i] = Thread.new(@workers[i]) do |worker|
          ActiveRecord::Base.connection_pool.with_connection do
            worker.run
          end
        end
        @threads[i].abort_on_exception = true
      end
      @threads.values.each(&:join)
    end

  end
end
