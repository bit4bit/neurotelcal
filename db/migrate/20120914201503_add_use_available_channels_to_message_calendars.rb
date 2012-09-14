class AddUseAvailableChannelsToMessageCalendars < ActiveRecord::Migration
  def change
    #Opcion de usar canales disponibles en el calendario para completar las llamadas esperadas
    add_column :message_calendars, :use_available_channels, :boolean, :default => false
  end
end
