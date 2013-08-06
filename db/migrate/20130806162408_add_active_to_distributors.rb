class AddActiveToDistributors < ActiveRecord::Migration
  def change
    add_column :distributors, :active, :boolean
  end
end
