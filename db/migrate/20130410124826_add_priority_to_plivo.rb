class AddPriorityToPlivo < ActiveRecord::Migration
  def change
    add_column :plivos, :priority, :integer, :default => 0
  end
end
