class CreateEntities < ActiveRecord::Migration
  def change
    create_table :entities do |t|
      t.string :name
      t.text :slogan
      t.string :phone
      t.string :direction
      t.string :leader
      t.text :description

      t.timestamps
    end
  end
end
