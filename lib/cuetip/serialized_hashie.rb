require 'hashie/mash'

module Cuetip
  class SerializedHashie < Hashie::Mash

    def self.dump(obj)
      obj.reject! { |k,v| v.blank? }
      obj.each do |key, value|
        if value.is_a?(Array)
          obj[key] = value.reject(&:blank?)
        end
      end
      ActiveSupport::JSON.encode(obj.to_h)
    end

    def self.load(raw_hash)
      new(JSON.parse(raw_hash || "{}"))
    end

  end
end
