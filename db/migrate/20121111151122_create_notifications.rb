class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.integer :user_id
      t.text :msg
      t.string :type_msg

      t.timestamps
    end
  end
end
