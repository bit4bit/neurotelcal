class CreateMessageCalendars < ActiveRecord::Migration
  def change
    create_table :message_calendars do |t|
      t.integer :message_id
      t.datetime :start
      t.datetime :stop

      t.timestamps
    end
  end
end
