class AddNotesToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :notes, :text, :default => ''
  end
end
