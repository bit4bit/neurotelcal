class CreatePlivoCalls < ActiveRecord::Migration
  def change
    create_table :plivo_calls do |t|
      t.string :uuid
      t.string :status
      t.string :hangup_enumeration
      t.text :data
      t.integer :call_id

      t.timestamps
    end
  end
end
