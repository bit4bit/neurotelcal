class AddLastClientParseIdToMessage < ActiveRecord::Migration
  def change
    #el ultimo cliente que se llamo
    add_column :messages, :last_client_parse_id, :integer, :default => 0 
  end
end
