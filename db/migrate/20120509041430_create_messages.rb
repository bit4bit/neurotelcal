# -*- coding: utf-8 -*-
class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :name
      t.text :description
      t.integer :group_id

      #si ya termino de llamar todos los clientes de la campaña
      t.boolean :processed
      #fecha de iniciar la llamada
      t.datetime :call
      t.integer :repeat_interval, :default => 0
      t.datetime :repeat_until
      
      t.boolean :anonymous, :default => false
      t.timestamps
    end
  end
end
