class CreatePlivoCalls < ActiveRecord::Migration
  def change
    create_table :plivo_calls do |t|
      t.integer :plivo_id
      t.string :number # a quien se llama
      t.string :uuid
      t.string :status
      t.string :hangup_enumeration
      t.text :data
      t.integer :step, :default => 0
      t.integer :call_id
      t.boolean :end, :default => false
      t.timestamps
    end
  end
end
