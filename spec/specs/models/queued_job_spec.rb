# frozen_string_literal: true

require 'spec_helper'

describe Cuetip::Models::QueuedJob do
  context 'locking' do
    subject(:queued_job) { Cuetip::Models::QueuedJob.create! }

    it 'should lock once' do
      expect(Cuetip::Models::QueuedJob.find_and_lock(queued_job.id)).to eq queued_job
    end

    it 'should not lock twice' do
      expect(Cuetip::Models::QueuedJob.find_and_lock(queued_job.id)).to eq queued_job
      expect(Cuetip::Models::QueuedJob.find_and_lock(queued_job.id)).to eq nil
    end
  end
end
