class AddIndexToPlivoCalls < ActiveRecord::Migration
  def change
    add_index :plivo_calls, :uuid
  end
end
