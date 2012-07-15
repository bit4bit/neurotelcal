class CreatePlivos < ActiveRecord::Migration
  def change
    create_table :plivos do |t|
      t.string :app_url, :default => 'http://localhost:3000'
      t.string :api_url, :default => 'http://localhost:8088'
      t.string :sid
      t.string :auth_token
      t.string :status #estado de este servic
      #http://www.plivo.org/docs/restapis/call/making-an-outbound-call/
      t.string :gateways
      t.string :gateway_codecs, :default => "PCMA,PCMU"
      t.integer :gateway_timeouts, :default => 60
      t.integer :gateway_retries, :default => 1
      t.string :caller_name, :default => 'Neurotelcal'
      t.integer :campaign_id
      t.integer :channels, :default => 100 #maximo de  canales o llamadas
      t.timestamps
    end
  end
end
