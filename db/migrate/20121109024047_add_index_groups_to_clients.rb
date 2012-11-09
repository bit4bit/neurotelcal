class AddIndexGroupsToClients < ActiveRecord::Migration
  def change
    add_index :clients, :group_id
  end
end
