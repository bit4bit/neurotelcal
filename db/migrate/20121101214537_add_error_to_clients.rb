class AddErrorToClients < ActiveRecord::Migration
  def change
    add_column :clients, :error, :boolean, :default => false
    add_column :clients, :error_msg, :string, :default => ""
  end
end
