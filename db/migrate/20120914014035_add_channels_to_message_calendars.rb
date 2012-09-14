class AddChannelsToMessageCalendars < ActiveRecord::Migration
  def change
    #canales a usar para llamar esto limita la cantidad
    #de llamadas simultaneas por calendario permitiendo
    #que en determinadas horas o dias se pueda incrementar
    #la cantidad de llamadas.
    add_column :message_calendars, :channels, :integer, :default => 1
  end
end
