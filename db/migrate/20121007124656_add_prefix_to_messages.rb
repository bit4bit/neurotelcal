class AddPrefixToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :prefix, :string, :default => ""
  end
end
