module Cuetip
  module Models
    class QueuedJob < ActiveRecord::Base

      self.table_name = 'cuetip_job_queue'

      def requeue(attributes = {})
        self.attributes = attributes
        self.locked_by = nil
        self.locked_at = nil
        self.save!
        self
      end

    end
  end
end
