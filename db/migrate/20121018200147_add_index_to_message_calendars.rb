class AddIndexToMessageCalendars < ActiveRecord::Migration
  def change
    add_index :message_calendars, :message_id
  end
end
