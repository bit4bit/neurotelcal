class AddCallsToClients < ActiveRecord::Migration
  def change
    #conteo de llamadas realizadas
    add_column :clients, :calls, :integer, :default => 0
  end
end
