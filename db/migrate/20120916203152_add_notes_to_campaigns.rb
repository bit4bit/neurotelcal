class AddNotesToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :notes, :text
  end
end
