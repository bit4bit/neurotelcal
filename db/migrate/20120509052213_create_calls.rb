class CreateCalls < ActiveRecord::Migration
  def change
    create_table :calls do |t|
      t.integer :message_id
      t.integer :client_id
      t.integer :length
      t.boolean :completed_p, :default => false
      #cuando se ingreso para ser llamada
      t.datetime :enter
      #y cuando por fin se termino de escuchar
      t.datetime :terminate
      t.datetime :enter_listen
      t.datetime :terminate_listen
      #digitos presionados
      t.string :digits
      t.string :status
      #mirar http://wiki.freeswitch.org/wiki/Hangup_causes
      t.string :hangup_enumeration
      t.timestamps
    end
  end


end
