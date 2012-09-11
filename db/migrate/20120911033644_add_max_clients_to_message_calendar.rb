class AddMaxClientsToMessageCalendar < ActiveRecord::Migration
  def change
    #maximo clientes a llamar
    add_column :message_calendars, :max_clients, :integer, :default => 0
  end
end
