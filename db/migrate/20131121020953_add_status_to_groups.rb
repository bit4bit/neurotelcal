class AddStatusToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :status, :string, :default => 'end'
  end
end
