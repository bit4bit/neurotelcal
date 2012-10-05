# -*- coding: utf-8 -*-
require 'csv'

class ReportsController < ApplicationController
  def index
    @calls = Call.paginate :page => params[:page], :order => 'created_at DESC'
    @report = {:general => {}}
    #por estado de cuelgue
    @report[:general][:by_hangup_enumeration] = Call.group(:hangup_enumeration).count


    #estadisticos
    @report[:general][:statistical] = {
      :response_ivr => PlivoCall.where('data LIKE "%%result%%"').count,
      :calls_completed => PlivoCall.count
    }
    
  end
  
  def export
  end
  
  def export_with_format
    print params


    date_start = DateTime.civil(params[:start][:year].to_i, params[:start][:month].to_i,params[:start][:day].to_i, params[:start][:hour].to_i,params[:start][:minute].to_i)
    date_end = DateTime.civil(params[:end][:year].to_i, params[:end][:month].to_i,params[:end][:day].to_i, params[:end][:hour].to_i,params[:end][:minute].to_i)
    duration_expected = params[:duration_expected].to_i
    @date_start = date_start
    @date_end = date_end
    @duration_expected = duration_expected
    @entity = Entity.first #@todo esto es caspa

    @summary = {
      :answer_total => 0,
      :ivr_total => 0,
      :complete_duration_expected => 0,
      :not_complete_duration_expected => 0
    }
    @summary[:answer_total] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0', date_start, date_end).count
    @summary[:ivr_total] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('data like "%%result%%" and start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0', date_start, date_end).count
    @summary[:complete_duration_expected] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and billsec >= ?', date_start, date_end, duration_expected).count
    @summary[:not_complete_duration_expected] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and billsec <= ?', date_start, date_end, duration_expected).count
    
    @summary_by_campaign = {}
    Message.where('anonymous = 0').each do |message|
      msummary = {}
      msummary[:answer_total] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and messages.id = ? ', date_start, date_end, message.id).count
      msummary[:ivr_total] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('data like "%%result%%" and start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and messages.id = ? ', date_start, date_end, message.id).count
      msummary[:complete_duration_expected] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and billsec >= ? and messages.id = ? ', date_start, date_end, duration_expected, message.id).count
      msummary[:not_complete_duration_expected] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and billsec <= ? and messages.id = ? ', date_start, date_end, duration_expected, message.id).count
      msummary[:cdrs] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and messages.id = ?', date_start, date_end, message.id)
      @summary_by_campaign[message.name] = msummary

      #@todo COMO OBTENEMOS EL SUMARIO DE LA ENCUESTA POR PREGUNTA Y RESPUESTA??
    end

    
    #@cdrs = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid').joins('left join calls on calls.id = plivo_calls.call_id').joins('left join messages on messages.id = calls.message_id').joins('left join groups on groups.id = messages.group_id').joins('left join campaigns on campaigns.id = groups.campaign_id').joins('left join entities on entities.id = campaigns.entity_id').select('entities.name as entity_name, campaigns.name as campaign_name, destination_number')
    respond_to do |format|
      format.xml
    end
    
  end
  
  def export_csv_index
    csv_string = CSV.generate do |csv|
      csv << ["Entidad", "Campaña", "Client", "Mensaje", "Programado para", "LLamada inicio", "Llamada finalizo", "Contesta inicio", "Contesta finalizo", "Duración", "Estado Final"]
      Call.find_each  do |call|
        #no se exporta los mensajes anonimos
        next if call.message.nil?
        begin
          csv << [call.message.group.campaign.entity.name, call.message.group.campaign.name, call.client.fullname, call.message.name, call.message.call, call.enter, call.terminate, call.enter_listen, call.terminate_listen, call.length,  call.hangup_status]
        rescue
        end
        
      end

    end
    
    send_data csv_string, :type => "text/csv", :filename => "export_#{session.object_id}.csv", :disposition => 'attachment'
  end

end
