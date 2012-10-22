class AddMotoringCampaignToUsers < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.boolean :admin, :default => false
      t.boolean :monitor, :default => false
      t.integer :monitor_campaign_id, :default => 0
    end
  end
end
