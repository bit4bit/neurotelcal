class AddBillDurationToPlivoCalls < ActiveRecord::Migration
  def change
    add_column :plivo_calls, :bill_duration, :integer, :default => 0
  end
end
