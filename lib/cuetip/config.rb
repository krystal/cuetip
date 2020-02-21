# frozen_string_literal: true

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

    # Define a job event callback
    def on(event, &block)
      callbacks[event.to_sym] ||= []
      callbacks[event.to_sym] << block
    end

    # Return all callbacks
    def callbacks
      @callbacks ||= Hash.new
    end

    # Emit some callbacks
    def emit(event, *args)
      return unless callbacks[event.to_sym]

      callbacks[event.to_sym].each do |callback|
        callback.call(*args)
      end
    end
  end
end
