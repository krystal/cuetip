# frozen_string_literal: true

require 'spec_helper'

describe Cuetip::Job do
  context '.queue' do
    it 'should queue a job' do
      job = Cuetip::Job.queue
      expect(job).to be_a(Cuetip::Models::Job)
      expect(job.class_name).to eq 'Cuetip::Job'
      expect(job.params).to be_a Hash
    end

    it 'should accept parameters' do
      job = Cuetip::Job.queue('test' => 'hello')
      expect(job.params['test']).to eq 'hello'
    end

    it 'should allow configuration to be set from a block' do
      job = Cuetip::Job.queue do |job|
        job.queue_name = 'anotherqueue'
      end
      expect(job.queue_name).to eq 'anotherqueue'
    end
  end

  context '#prune' do
    it 'should prune jobs created before the specified date' do
      job = Cuetip::Job.queue

      job.update(created_at: 2.months.ago)

      expect(Cuetip::Models::Job.find_by(id: job.id)).to eq job

      Cuetip::Job.prune(1.month.ago)

      expect(Cuetip::Models::Job.find_by(id: job.id)).to eq nil
    end
  end
end
