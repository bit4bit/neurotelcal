class AddCampaignIdToArchive < ActiveRecord::Migration
  def change
    add_column :archives, :campaign_id, :integer
  end
end
