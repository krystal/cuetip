module Cuetip
  class Config

    # The number of worker threads to run
    def worker_threads
      @worker_threads || 1
    end
    attr_writer :worker_threads

    # The length of time between polling
    def polling_interval
      @polling_interval || 10
    end
    attr_writer :polling_interval

    # Is multicast broadcasting enabled?
    def multicast?
      @multicast == true
    end
    attr_writer :multicast

    # What port should be used for multicast?
    def multicast_port
      @multicast_port ||= 34900
    end
    attr_writer :multicast_port

    # What scope should be sent with any packets to identify this application
    def multicast_scope
      @multicast_scope ||= "genericapp"
    end
    attr_writer :multicast_scope

    # Return the logger
    def logger
      @logger ||= Logger.new(STDOUT)
    end
    attr_writer :logger

    # Set/return an exception handler
    def exception_handler(&block)
      if block_given?
        @exception_handler = block
      else
        @exception_handler
      end
    end

  end
end
