class AddMaxClientsToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :max_clients, :integer, :default => 0 #maxima cantidad de clientes a enviar este mensaje
  end
end
