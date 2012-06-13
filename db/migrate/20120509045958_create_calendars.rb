class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.string :name
      t.integer :interval
      t.datetime :do_call
      t.integer :campaign_id

      t.timestamps
    end
  end
end
