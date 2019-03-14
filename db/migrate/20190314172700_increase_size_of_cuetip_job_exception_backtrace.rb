class IncreaseSizeOfCuetipJobExceptionBacktrace < ActiveRecord::Migration[5.0]
  def change
    change_column :cuetip_jobs, :exception_backtrace, :text, limit: 2.megabytes
    change_column :cuetip_jobs, :exception_message, :text, limit: 2.megabytes
  end
end
