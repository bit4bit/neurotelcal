class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.string :fullname
      t.string :phonenumber
      t.integer :campaign_id
      t.integer :group_id

      t.timestamps
    end
  end
end
