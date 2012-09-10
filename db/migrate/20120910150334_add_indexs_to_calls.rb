class AddIndexsToCalls < ActiveRecord::Migration
  def change
    add_index :calls, [:message_id, :client_id]
  end
end
