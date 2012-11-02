class AddLastCallAtToClients < ActiveRecord::Migration
  def change
    add_column :clients, :last_call_at, :datetime, :default => nil
  end
end
