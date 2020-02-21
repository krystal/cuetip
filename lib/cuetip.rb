# frozen_string_literal: true

require 'cuetip'
require 'cuetip/config'
require 'cuetip/job'
require 'cuetip/version'

module Cuetip
  def self.config
    @config ||= Config.new
  end

  def self.logger
    config.logger
  end

  def self.configure(&block)
    block.call(config)
  end
end

require 'cuetip/engine' if defined?(Rails)
