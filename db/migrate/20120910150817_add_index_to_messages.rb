class AddIndexToMessages < ActiveRecord::Migration
  def change
    add_index :messages, :group_id
  end
end
