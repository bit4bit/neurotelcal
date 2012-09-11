class AddMessageCalendarToCalls < ActiveRecord::Migration
  def change
    #enlace al calendario donde se realizo la llamada
    add_column :calls, :message_calendar_id, :integer, :default => 0
  end
end
