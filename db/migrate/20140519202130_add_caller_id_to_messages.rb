class AddCallerIdToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :caller_id, :string
  end
end
