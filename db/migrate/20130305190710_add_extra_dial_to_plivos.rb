class AddExtraDialToPlivos < ActiveRecord::Migration
  def change
    change_table :plivos do |t|
      t.string :extra_dial, :default => 'leg_delay_start=1,bridge_early_media=true,hangup_after_bridge=true'
    end
  end
end
