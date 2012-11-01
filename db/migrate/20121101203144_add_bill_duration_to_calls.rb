class AddBillDurationToCalls < ActiveRecord::Migration
  def change
    add_column :calls, :bill_duration, :integer, :default => 0
  end
end
