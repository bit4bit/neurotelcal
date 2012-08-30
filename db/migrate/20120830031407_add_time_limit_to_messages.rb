class AddTimeLimitToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :time_limit, :integer, :default => 0
  end
end
