class AddPriorityToClients < ActiveRecord::Migration
  def change
    add_column :clients, :priority, :integer, :default => 0
  end
end
