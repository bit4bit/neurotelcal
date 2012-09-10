class AddPriorityToMessage < ActiveRecord::Migration
  def change
    add_column :messages, :priority, :integer, :default => 0
  end
end
