class AddIndexToGroups < ActiveRecord::Migration
  def change
    add_index :groups, :campaign_id
  end
end
