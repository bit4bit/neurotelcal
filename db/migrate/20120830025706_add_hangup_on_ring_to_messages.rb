class AddHangupOnRingToMessages < ActiveRecord::Migration
  def change
    change_table :messages do |t|
      t.integer :hangup_on_ring, :default =>  4 #en segundos
    end
  end
end
