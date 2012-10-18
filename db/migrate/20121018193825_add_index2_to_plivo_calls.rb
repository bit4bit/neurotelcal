class AddIndex2ToPlivoCalls < ActiveRecord::Migration
  def change
    add_index :plivo_calls, :end
    add_index :plivo_calls, [:end, :plivo_id]

  end
end
