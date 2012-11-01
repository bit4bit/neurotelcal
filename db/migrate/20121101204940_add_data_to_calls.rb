class AddDataToCalls < ActiveRecord::Migration
  def change
    add_column :calls, :data, :text
  end
end
