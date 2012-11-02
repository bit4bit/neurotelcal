class ChangeProcessedFromMessages < ActiveRecord::Migration
  def up
  end

  def change
    change_column :messages, :processed, :boolean, :default => false
  end
  
  def down
  end
end
