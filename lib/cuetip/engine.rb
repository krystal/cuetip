# frozen_string_literal: true

module Cuetip
  class Engine < Rails::Engine #:nodoc:
    engine_name 'cuetip'

    # Make `config.active_job.queue_adapter = :cuetip` work.
    ActiveSupport.on_load(:active_job) do
      require 'active_job/queue_adapters/cuetip_adapter'
    end
  end
end
