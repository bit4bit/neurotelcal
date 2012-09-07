class AddEntityToCampaign < ActiveRecord::Migration
  def change
    add_column :campaigns, :entity_id, :integer
  end
end
