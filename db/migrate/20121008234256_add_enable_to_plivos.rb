class AddEnableToPlivos < ActiveRecord::Migration
  def change
    add_column :plivos, :enable, :boolean, :default => true
  end
end
