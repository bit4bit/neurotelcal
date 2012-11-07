class AddProcessingToArchive < ActiveRecord::Migration
  def change
    add_column :archives, :processing, :boolean, :default => false
  end
end
