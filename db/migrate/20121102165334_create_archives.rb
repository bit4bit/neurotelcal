class CreateArchives < ActiveRecord::Migration
  def change
    create_table :archives do |t|
      t.integer :version
      t.string :name
      t.timestamps
    end
  end
end
