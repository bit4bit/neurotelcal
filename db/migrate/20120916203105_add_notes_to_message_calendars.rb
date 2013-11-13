class AddNotesToMessageCalendars < ActiveRecord::Migration
  def change
    add_column :message_calendars, :notes, :text
  end
end
