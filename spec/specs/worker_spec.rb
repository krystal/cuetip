# frozen_string_literal: true

require 'spec_helper'
require 'cuetip/worker'
require 'cuetip/worker_group'

describe Cuetip::Worker do
  context 'running' do
    subject(:worker_group) { Cuetip::WorkerGroup.new(1) }
    subject(:worker)     { Cuetip::Worker.new(worker_group, 0) }
    subject(:job)        { Cuetip::Models::Job.create! }
    subject(:queued_job) { Cuetip::Models::QueuedJob.create!(job: job) }

    it 'should execute a job' do
      allow(Cuetip::Models::QueuedJob).to receive(:find_and_lock).and_return(queued_job)
      allow(job).to receive(:execute)
      worker.run_once
      expect(job).to have_received(:execute)
    end
  end
end
