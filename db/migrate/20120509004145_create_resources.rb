class CreateResources < ActiveRecord::Migration
  def change
    create_table :resources do |t|
      t.string :name
      t.string :type_file
      t.string :file
      t.integer :campaign_id

      t.timestamps
    end
  end

  def self.down
    drop_table :resources
  end
end
