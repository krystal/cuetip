# frozen_string_literal: true

class CreateCuetipJobQueueTable < ActiveRecord::Migration[5.0]
  def change
    create_table :cuetip_job_queue do |t|
      t.integer :job_id
      t.string :queue_name, :locked_by
      t.datetime :locked_at
      t.datetime :run_after
    end
  end
end
