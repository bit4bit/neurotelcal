class CreateDistributors < ActiveRecord::Migration
  def change
    create_table :distributors do |t|
      t.references :campaign
      t.references :plivo
      t.string :filter
      t.string :description

      t.timestamps
    end
    add_index :distributors, :campaign_id
    add_index :distributors, :plivo_id
  end
end
