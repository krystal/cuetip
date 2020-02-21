# frozen_string_literal: true

require 'spec_helper'

describe Cuetip::Models::Job do
  context 'on creation' do
    subject(:job) { Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', params: {}) }

    it 'should be added to the queue' do
      expect(job.queued_job).to be_a(Cuetip::Models::QueuedJob)
      expect(job.queued?).to be true
    end

    it 'should be pending' do
      expect(job.status).to eq 'Pending'
    end
  end

  context 'expired jobs' do
    it 'should have an expiry date' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', ttl: 60)
      expect(job.expires_at).to be_a(Time)
      expect(job.expires_at).to be > Time.now
    end

    it 'should not have expired' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', ttl: 60)
      expect(job.expired?).to be false
    end

    it 'should have expired when appropriate' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', ttl: 60, created_at: 2.minutes.ago)
      expect(job.expired?).to be true
    end

    it 'should not have expired when no TTL' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', ttl: nil)
      expect(job.expired?).to be false
    end

    it 'should not execute and should mark the job as expired' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', ttl: 10, created_at: 1.minute.ago)
      expect(job.execute).to be false
      expect(job.queued?).to be false
      expect(job.status).to eq 'Expired'
    end
  end

  context 'retrying on failure' do
    it 'should retry when executions is less than the maximum allowed' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', retry_count: 3, retry_interval: 10, executions: 1)
      expect(job.requeue_on_failure?).to be true

      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', retry_count: 1, retry_interval: 10, executions: 1)
      expect(job.requeue_on_failure?).to be true

      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', retry_count: 0, retry_interval: 10, executions: 1)
      expect(job.requeue_on_failure?).to be false
    end
  end

  context 'future jobs' do
    it 'should be queued to run in the future if a delay is provided' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', delay_execution: 10.minutes)
      expect(job.queued_job.run_after).to be > 9.minutes.from_now
    end

    it 'should be queued to run in the future if a time is provided' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', run_after: 10.minutes.from_now)
      expect(job.queued_job.run_after).to be > 9.minutes.from_now
    end
  end

  context 'executing' do
    it 'should mark the job as running while it runs' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job')
      the_instance = nil
      job.execute do |instance|
        the_instance = instance
        allow(instance).to receive(:perform) do
          expect(job.status).to eq 'Running'
        end
      end
      expect(the_instance).to have_received(:perform)
    end

    it 'should add a start time when it starts' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job')
      job.execute
      expect(job.started_at).to be_a(Time)
    end

    it 'should increment the number of times the job has run' do
      job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job')
      expect(job.executions).to eq 0
      job.execute
      expect(job.executions).to eq 1
      job.execute
      expect(job.executions).to eq 2
    end

    context 'successful jobs' do
      it 'should be marked as complete with a finished time' do
        job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job')
        job.execute
        expect(job.finished_at).to be_a Time
        expect(job.status).to eq 'Complete'
      end

      it 'should no longer be in the queue' do
        job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job')
        job.execute
        expect(job.queued?).to be false
        expect(job.queued_job).to be nil
      end
    end

    context 'jobs with exceptions and no retry' do
      it 'should be marked as failed and store the exception' do
        job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job')
        job.execute do |instance|
          allow(instance).to receive(:perform) do
            raise StandardError, 'An example test suite error'
          end
        end
        expect(job.status).to eq 'Failed'
        expect(job.exception_class).to eq 'StandardError'
        expect(job.exception_message).to eq 'An example test suite error'
        expect(job.exception_backtrace).to_not be_blank
      end

      it 'should no longer be in the queue' do
        job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job')
        job.execute
        expect(job.queued?).to be false
        expect(job.queued_job).to be nil
      end
    end

    context 'jobs with exceptions with a retry' do
      it 'should marked as pending with an exception' do
        job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', retry_count: 3, retry_interval: 10)
        job.execute do |instance|
          allow(instance).to receive(:perform) do
            raise StandardError, 'An example test suite error'
          end
        end
        expect(job.exception_class).to eq 'StandardError'
        expect(job.status).to eq 'Pending'
      end

      it 'should be marked as failed when the number of retries has been reached' do
        job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', retry_count: 3, retry_interval: 10)
        4.times do |i|
          job.execute do |instance|
            allow(instance).to receive(:perform) do
              raise StandardError, 'An example test suite error'
            end
          end
          expect(job.executions).to eq i + 1
          if i == 3
            expect(job.status).to eq 'Failed'
            expect(job.queued?).to be false
          else
            expect(job.status).to eq 'Pending'
            expect(job.queued?).to be true
          end
        end
      end
    end

    context 'callbacks' do
      it 'should run callbacks when finished' do
        callback_run = false
        job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', retry_count: 3, retry_interval: 10)
        Cuetip.config.on(:exception) { |job| callback_run = true }
        job.execute do |instance|
          allow(instance).to receive(:perform) do
            raise StandardError, 'An example test suite error'
          end
        end
        expect(callback_run).to be true
      end

      it 'should run callbacks when finished' do
        callback_run = false
        job = Cuetip::Models::Job.create!(class_name: 'Cuetip::Job', retry_count: 3, retry_interval: 10)
        Cuetip.config.on(:finished) { |job| callback_run = true }
        job.execute
        expect(callback_run).to be true
      end
    end
  end
end
