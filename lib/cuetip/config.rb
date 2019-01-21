require 'cuetip/events'

module Cuetip
  class Config

    include Cuetip::Events

    # The length of time between polling
    def polling_interval
      @polling_interval || 10
    end
    attr_writer :polling_interval

    # Return the logger
    def logger
      @logger ||= Logger.new(STDOUT)
    end
    attr_writer :logger

  end
end
