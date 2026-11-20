# frozen_string_literal: true

require 'spec_helper'
require 'active_job/queue_adapters/cuetip_adapter'

ActiveJob::Base.logger = Logger.new(nil)

class CuetipAdapterTestJob < ActiveJob::Base
  queue_as :reports

  cattr_accessor :performed, default: []

  def perform(*args)
    self.class.performed << args
  end
end

class CuetipAdapterFailingJob < ActiveJob::Base
  def perform
    raise ArgumentError, 'boom'
  end
end

class CuetipAdapterRetryingJob < ActiveJob::Base
  retry_on ArgumentError, wait: 30.seconds, attempts: 2

  def perform
    raise ArgumentError, 'try again'
  end
end

describe ActiveJob::QueueAdapters::CuetipAdapter do
  around do |example|
    [CuetipAdapterTestJob, CuetipAdapterFailingJob, CuetipAdapterRetryingJob].each { |k| k.queue_adapter = :cuetip }
    CuetipAdapterTestJob.performed = []
    example.run
  end

  def cuetip_job_for(active_job)
    Cuetip::Models::Job.find(active_job.provider_job_id)
  end

  it 'is found by `queue_adapter = :cuetip`' do
    expect(CuetipAdapterTestJob.queue_adapter).to be_a(described_class)
  end

  it 'does not defer enqueueing until after commit, as jobs share the app database' do
    expect(described_class.new.enqueue_after_transaction_commit?).to be false
  end

  context 'perform_later' do
    subject(:active_job) { CuetipAdapterTestJob.perform_later(1, 'two') }

    it 'creates a pending cuetip job on the Active Job queue' do
      job = cuetip_job_for(active_job)
      expect(job.class_name).to eq 'Cuetip::ActiveJobWrapper'
      expect(job.params.job_class).to eq 'CuetipAdapterTestJob'
      expect(job.queue_name).to eq 'reports'
      expect(job.status).to eq 'Pending'
      expect(job.queued_job.queue_name).to eq 'reports'
    end

    it 'does not expire or retry at the cuetip level' do
      job = cuetip_job_for(active_job)
      expect(job.ttl).to be_nil
      expect(job.expired?).to be false
      expect(job.retry_count).to eq 0
    end

    it 'runs the Active Job when cuetip executes it' do
      expect(cuetip_job_for(active_job).execute).to be true
      expect(CuetipAdapterTestJob.performed).to eq [[1, 'two']]
      expect(cuetip_job_for(active_job).status).to eq 'Complete'
    end

    it 'preserves blank and complex arguments' do
      time = Time.utc(2026, 1, 2, 3, 4, 5)
      args = [nil, '', [], {}, { 'a' => [1, nil, ''] }, { sym: :value }, time]
      active_job = CuetipAdapterTestJob.perform_later(*args)
      cuetip_job_for(active_job).execute
      expect(CuetipAdapterTestJob.performed).to eq [args]
    end

    it 'is picked up by a worker listening on the job queue' do
      active_job
      Cuetip::Models::QueuedJob.where.not(job_id: active_job.provider_job_id).delete_all
      expect(Cuetip::Worker.new(nil, 0, ['reports']).run_once).to be true
      expect(CuetipAdapterTestJob.performed).to eq [[1, 'two']]
    end
  end

  context 'set(wait:)' do
    it 'schedules the cuetip job for later and does not expire it' do
      active_job = CuetipAdapterTestJob.set(wait: 1.day).perform_later
      job = cuetip_job_for(active_job)
      expect(job.queued_job.run_after).to be_within(5.seconds).of(1.day.from_now)
      expect(job.expired?).to be false
      expect(Cuetip::Models::QueuedJob.pending.where(id: job.queued_job.id)).to be_empty
    end
  end

  context 'failures' do
    it 'marks the cuetip job as failed with the exception' do
      job = cuetip_job_for(CuetipAdapterFailingJob.perform_later)
      expect(job.execute).to be false
      job.reload
      expect(job.status).to eq 'Failed'
      expect(job.exception_class).to eq 'ArgumentError'
      expect(job.exception_message).to eq 'boom'
      expect(job.queued?).to be false
    end

    it 'lets Active Job retry_on re-enqueue through the adapter' do
      job = cuetip_job_for(CuetipAdapterRetryingJob.perform_later)
      expect { job.execute }.to change { Cuetip::Models::Job.where(class_name: 'Cuetip::ActiveJobWrapper').count }.by(1)

      retry_job = Cuetip::Models::Job.order(:id).last
      expect(JSON.parse(retry_job.params.job_data)['executions']).to eq 1
      expect(retry_job.queued_job.run_after).to be > Time.now
    end
  end
end
