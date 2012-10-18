class AddIndexToCalls < ActiveRecord::Migration
  def change
    add_index :calls, :terminate
    add_index :calls, [:client_id, :hangup_enumeration]
    add_index :calls, [:message_calendar_id, :hangup_enumeration]
  end
end
