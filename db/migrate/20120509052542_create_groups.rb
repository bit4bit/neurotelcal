class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.integer :campaign_id

      t.timestamps
    end
  end


  def self.down
    drop_table :groups
  end
end
