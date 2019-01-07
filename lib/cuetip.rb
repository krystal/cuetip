require 'active_support'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/numeric/time'
require 'cuetip/config'
require 'cuetip/models/job'
require 'cuetip/models/queued_job'
require 'cuetip/job'
require 'cuetip/monitor'
require 'cuetip/worker'
require 'cuetip/supervisor'

module Cuetip

  def self.config
    @config ||= Config.new
  end

  def self.configure(&block)
    blocak.call(self.config)
  end

end