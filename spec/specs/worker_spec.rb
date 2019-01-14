require 'spec_helper'

describe Cuetip::Worker do

  context "running" do
  
    subject(:monitor)    { Cuetip::Monitor.new(nil) }
    subject(:worker)     { Cuetip::Worker.new(monitor) }
    subject(:job)        { Cuetip::Models::Job.create! }
    subject(:queued_job) { Cuetip::Models::QueuedJob.create!(:job => job) }

    it "should configure a pair of pipes" do
      worker.setup_pipes
      expect(worker.up_pipe).to be_a(IO)
      expect(worker.down_pipe).to be_a(IO)
    end

    it "should find a queued job" do
      allow(worker).to receive(:process_queued_job)

      worker.setup_pipes
      worker.monitor.run_job(queued_job)
      worker.run_once
      expect(worker).to have_received(:process_queued_job)
    end

    it "should execute a job" do
      allow(job).to receive(:execute)
      worker.process_queued_job(queued_job)
      expect(job).to have_received(:execute)
    end

  end

end
