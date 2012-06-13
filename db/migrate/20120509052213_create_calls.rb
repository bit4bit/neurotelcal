class CreateCalls < ActiveRecord::Migration
  def change
    create_table :calls do |t|
      t.integer :message_id
      t.integer :client_id
      t.integer :length
      t.boolean :completed_p, :default => false
      #cuando se ingreso para ser llamada
      t.datetime :entered
      #y cuando por fin fue escuchada
      t.datetime :listened
      t.string :status
      #mirar http://wiki.freeswitch.org/wiki/Hangup_causes
      t.string :hangup_enumeration
      t.timestamps
    end
  end


end
