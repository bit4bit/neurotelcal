# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120830031407) do

  create_table "calendars", :force => true do |t|
    t.integer  "message_id"
    t.datetime "start"
    t.datetime "stop"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "calls", :force => true do |t|
    t.integer  "message_id"
    t.integer  "client_id"
    t.integer  "length"
    t.boolean  "completed_p",        :default => false
    t.datetime "enter"
    t.datetime "terminate"
    t.datetime "enter_listen"
    t.datetime "terminate_listen"
    t.string   "digits"
    t.string   "status"
    t.string   "hangup_enumeration"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  create_table "campaigns", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "status"
    t.datetime "start"
    t.datetime "pause"
    t.datetime "stop"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "clients", :force => true do |t|
    t.string   "fullname"
    t.string   "phonenumber"
    t.integer  "campaign_id"
    t.integer  "group_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.integer  "campaign_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "message_calendars", :force => true do |t|
    t.integer  "message_id"
    t.datetime "start"
    t.datetime "stop"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "messages", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "group_id"
    t.boolean  "processed"
    t.datetime "call"
    t.datetime "call_end"
    t.boolean  "anonymous",      :default => false
    t.integer  "retries",        :default => 1
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "hangup_on_ring", :default => 4
    t.integer  "time_limit",     :default => 0
  end

  create_table "plivo_calls", :force => true do |t|
    t.integer  "plivo_id"
    t.string   "number"
    t.string   "uuid"
    t.string   "status"
    t.string   "hangup_enumeration"
    t.text     "data"
    t.integer  "step",               :default => 0
    t.integer  "call_id"
    t.boolean  "end",                :default => false
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.integer  "ring_count",         :default => 0
  end

  create_table "plivos", :force => true do |t|
    t.string   "app_url",          :default => "http://localhost:3000"
    t.string   "api_url",          :default => "http://localhost:8088"
    t.string   "sid"
    t.string   "auth_token"
    t.string   "status"
    t.string   "gateways"
    t.string   "gateway_codecs",   :default => "PCMA,PCMU"
    t.integer  "gateway_timeouts", :default => 60
    t.integer  "gateway_retries",  :default => 1
    t.string   "caller_name",      :default => "Neurotelcal"
    t.integer  "campaign_id"
    t.integer  "channels",         :default => 100
    t.datetime "created_at",                                            :null => false
    t.datetime "updated_at",                                            :null => false
  end

  create_table "resources", :force => true do |t|
    t.string   "name"
    t.string   "type_file"
    t.string   "file"
    t.integer  "campaign_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "hashed_password"
    t.string   "salt"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

end
