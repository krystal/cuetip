require 'socket'
require 'active_record'
require 'cuetip/models/job'

module Cuetip
  module Models
    class QueuedJob < ActiveRecord::Base

      PROCESS_IDENTIFIER = Socket.gethostname + ":#{Process.pid}"
      self.table_name = 'cuetip_job_queue'

      scope :pending, -> { where(:locked_at => nil).where('run_after is null or run_after < ?', Time.now) }
      belongs_to :job, :class_name => "Cuetip::Models::Job"

      # Unlock the job and allow it to be re-run elsewhere.
      def requeue(attributes = {})
        self.attributes = attributes
        self.locked_by = nil
        self.locked_at = nil
        self.save!
        self
      end

      # Generate a random lock ID to use in the locking process
      def self.generate_lock_id
        PROCESS_IDENTIFIER + ':' + rand(1000000000).to_s.rjust(9, '0')
      end

      # Simultaneously find an outstanding job and lock it
      def self.find_and_lock(queued_job_id = nil)
        lock_id = generate_lock_id
        if(queued_job_id)
          scope = self.where(:id => queued_job_id)
        else
          scope = self
        end
        count = scope.pending.limit(1).update_all(:locked_by => lock_id, :locked_at => Time.now)
        if count > 0
          QueuedJob.find_by_locked_by(lock_id)
        else
          nil
        end
      end

    end
  end
end
