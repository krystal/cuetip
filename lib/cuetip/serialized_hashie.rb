# frozen_string_literal: true

require 'hashie/mash'

module Cuetip
  class SerializedHashie < Hashie::Mash
    def self.dump(obj)
      obj.reject! { |_k, v| v.blank? }
      obj.each do |key, value|
        obj[key] = value.reject(&:blank?) if value.is_a?(Array)
      end
      ActiveSupport::JSON.encode(obj.to_h)
    end

    def self.load(raw_hash)
      new(JSON.parse(raw_hash || '{}'))
    end
  end
end
