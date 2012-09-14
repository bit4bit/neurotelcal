class AddTimeExpectedForCallToMessageCalendars < ActiveRecord::Migration
  def change
    #tiempo esperado por llamada, para determinar el total de llamadas en un rango de tiempos y
    #otros datos
    add_column :message_calendars, :time_expected_for_call, :integer, :default => 0
  end
end
