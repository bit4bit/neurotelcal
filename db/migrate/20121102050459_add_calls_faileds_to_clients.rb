class AddCallsFailedsToClients < ActiveRecord::Migration
  def change
    add_column :clients, :calls_faileds, :integer, :default => 0
  end
end
