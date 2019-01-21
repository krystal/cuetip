require 'cuetip/config'
require 'cuetip/job'
require 'cuetip/version'

module Cuetip

  def self.config
    @config ||= Config.new
  end

  def self.logger
    self.config.logger
  end

  def self.configure(&block)
    block.call(self.config)
  end

end

if defined?(Rails)
  require 'cuetip/engine'
end
