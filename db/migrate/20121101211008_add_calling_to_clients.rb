class AddCallingToClients < ActiveRecord::Migration
  def change
    #para evitar consultas, se guarda mantiene el estado
    #de las la llamada del cliente en el cliente
    add_column :clients, :calling, :boolean, :default => false
  end
end
