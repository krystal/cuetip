require 'spec_helper'

describe Cuetip::Models::QueuedJob do

  context "locking" do
    subject(:queued_job) { Cuetip::Models::QueuedJob.create! }

    it "should lock once" do
      expect(queued_job.lock!).to be true
    end

    it "should not lock twice" do
      expect(queued_job.lock!).to be true
      expect(queued_job.lock!).to be false
    end

  end

end