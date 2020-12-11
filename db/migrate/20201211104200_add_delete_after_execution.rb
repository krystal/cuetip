# frozen_string_literal: true

class AddDeleteAfterExecution < ActiveRecord::Migration[5.0]

  def change
    add_column :cuetip_jobs, :delete_after_execution, :boolean, default: false
  end

end
