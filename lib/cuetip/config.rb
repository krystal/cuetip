module Cuetip
  class Config

    DEFAULT_BEFORE_FORK = Proc.new { ActiveRecord::Base.clear_all_connections! }

    # The number of worker processes to run
    def workers
      @workers || 1
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
      @multicast_port || 34900
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

    # Set/return block to run before forking
    def before_fork(&block)
      if block_given?
        @before_fork = block
      else
        @before_fork || DEFAULT_BEFORE_FORK
      end
    end

    # Set/return block to run after forking
    def after_fork(&block)
      if block_given?
        @after_fork = block
      else
        @after_fork
      end
    end

  end
end
