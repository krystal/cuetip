require 'socket'
require 'active_record'

module Cuetip
  module Models
    class QueuedJob < ActiveRecord::Base

      PROCESS_IDENTIFIER = Socket.gethostname + ":#{Process.pid}"
      self.table_name = 'cuetip_job_queue'

      belongs_to :job, :class_name => "Cuetip::Models::Job"

      # Unlock the job and allow it to be re-run elsewhere.
      def requeue(attributes = {})
        self.attributes = attributes
        self.locked_by = nil
        self.locked_at = nil
        self.save!
        self
      end

      # Attempt to own this queued job by locking it with our process details.
      # Returns true if the job is now owned by this process or false if it
      # has been locked elsewhere.
      def lock!
        count = self.class.where(:id => self.id, :locked_by => nil).update_all(:locked_by => PROCESS_IDENTIFIER, :locked_at => Time.now)
        return count > 0
      end

    end
  end
end
