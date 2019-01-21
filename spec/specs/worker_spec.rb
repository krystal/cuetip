require 'spec_helper'

describe Cuetip::Worker do

  context "running" do
  
    subject(:worker)     { Cuetip::Worker.new }
    subject(:job)        { Cuetip::Models::Job.create! }
    subject(:queued_job) { Cuetip::Models::QueuedJob.create!(:job => job) }

    it "should execute a job" do
      allow(Cuetip::Models::QueuedJob).to receive(:find_and_lock).and_return(queued_job)
      allow(job).to receive(:execute)
      worker.run_once
      expect(job).to have_received(:execute)
    end

  end

end
