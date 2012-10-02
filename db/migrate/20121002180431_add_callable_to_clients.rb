class AddCallableToClients < ActiveRecord::Migration
  def change
    add_column :clients, :callable, :boolean, :default => true
    Client.reset_column_information

    #Se actualizan los clientes que ya se llamaron
    Client.all.each do |client|
      if Call.where(:client_id => client.id, :hangup_enumeration => PlivoCall::ANSWER_ENUMERATION).count > 0
        client.update_column(:callable, false)
      end
    end
    
  end
end
