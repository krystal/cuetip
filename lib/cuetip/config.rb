require 'active_support'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/numeric/time'

module Cuetip
  class Config

    # The length of time between polling
    def polling_interval
      @polling_interval || 5
    end
    attr_writer :polling_interval

    # The number of worker threads to run
    def worker_threads
      @worker_threads || 1
    end
    attr_writer :worker_threads

    # Return the logger
    def logger
      @logger ||= Logger.new(STDOUT)
    end
    attr_writer :logger

  end
end
