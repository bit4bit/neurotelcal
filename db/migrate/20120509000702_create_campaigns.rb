class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.string :name
      t.text :description
      t.integer :status #0: start, 1:end, 2:pause, 3:abort
      t.datetime :start
      t.datetime :pause
      t.datetime :stop
      t.timestamps
    end
  end
end
