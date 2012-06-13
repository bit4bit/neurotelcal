# -*- coding: utf-8 -*-
require 'csv'

class ReportsController < ApplicationController
  def index
    @calls = Call.paginate :page => params[:page], :order => 'created_at DESC'
  end

  def export_csv_index
    csv_string = CSV.generate do |csv|
      csv << ["Campaña", "Client", "Mensaje", "Programado para", "LLamada inicio", "Llamada finalizo", "Estado de Cuelgue"]
      Call.find_each  do |call|
        csv << [call.message.campaign.name, call.client.fullname, call.message.name, call.message.call, call.entered, call.listened, call.hangup_status]
      end

    end
    
    send_data csv_string, :type => "text/csv", :filename => "export_#{session.object_id}.csv", :disposition => 'attachment'
  end

end
