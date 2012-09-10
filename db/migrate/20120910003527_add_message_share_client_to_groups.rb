class AddMessageShareClientToGroups < ActiveRecord::Migration
  #Los messages comparten clientes, esto indica que si ya se realizo
  #un mensaje de un cliente este ya no se llama para otro mensaje
  def change
    add_column :groups, :messages_share_clients, :boolean, :default => true
  end
end
