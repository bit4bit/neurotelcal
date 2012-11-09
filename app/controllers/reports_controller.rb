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
    @entities = Entity.all
  end
  
  def export_with_format
    print params


    date_start = DateTime.civil(params[:start][:year].to_i, params[:start][:month].to_i,params[:start][:day].to_i, params[:start][:hour].to_i,params[:start][:minute].to_i)
    date_end = DateTime.civil(params[:end][:year].to_i, params[:end][:month].to_i,params[:end][:day].to_i, params[:end][:hour].to_i,params[:end][:minute].to_i)
    duration_expected = params[:duration_expected].to_i
    @date_start = date_start
    @date_end = date_end
    @duration_expected = duration_expected
    @entity = Entity.where(:id => params[:entity]).first #@todo esto es caspa

    @summary = {
      :answer_total => 0,
      :ivr_total => 0,
      :complete_duration_expected => 0,
      :not_complete_duration_expected => 0
    }
    @summary[:answer_total] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id left join groups on groups.id = messages.group_id left join campaigns on campaigns.id = groups.campaign_id left join entities on entities.id = campaigns.entity_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and entities.id = ? ', date_start, date_end, @entity.id).count
    @summary[:ivr_total] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id').where('data like "%%result%%" and start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0', date_start, date_end).count
    @summary[:complete_duration_expected] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id left join groups on groups.id = messages.group_id left join campaigns on campaigns.id = groups.campaign_id left join entities on entities.id = campaigns.entity_id ').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and billsec >= ? and entities.id = ? ', date_start, date_end, duration_expected, @entity.id).count
    @summary[:not_complete_duration_expected] = Cdr.joins('left join plivo_calls on plivo_calls.uuid = cdrs.uuid left join calls on calls.id = plivo_calls.call_id left join messages on messages.id = calls.message_id left join groups on groups.id = messages.group_id left join campaigns on campaigns.id = groups.campaign_id left join entities on entities.id = campaigns.entity_id').where('start_stamp >= ? and end_stamp <= ? and messages.anonymous = 0 and billsec <= ? and entities.id = ? ', date_start, date_end, duration_expected, @entity.id).count
    
    @summary_by_campaign = {}
    Message.joins('left join groups on groups.id = messages.group_id left join campaigns on campaigns.id = groups.campaign_id left join entities on entities.id = campaigns.entity_id').where('anonymous = 0 and entities.id = ? ', @entity.id).each do |message|
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
  
  def new_export_csv
    @campaigns = Campaign.all
  end
  
  def export_csv
    @campaigns = Campaign.all
    date_start = DateTime.civil(params[:start][:year].to_i, params[:start][:month].to_i,params[:start][:day].to_i, params[:start][:hour].to_i,params[:start][:minute].to_i)
    date_end = DateTime.civil(params[:end][:year].to_i, params[:end][:month].to_i,params[:end][:day].to_i, params[:end][:hour].to_i,params[:end][:minute].to_i)
    @campaign = Campaign.where(:id => params[:campaign]).first #@todo esto es caspa

    csv_string = CSV.generate do |csv|
      csv << ["Entidad", "Campaña", "Client", "Mensaje", "Programado para", "LLamada Realizada", "Llamada Contestada", "Duracion Proceso", "Duración Cobro", "Estado Final", "Respuestas"]
      Call.where("created_at >= ? and created_at <= ? ", date_start, date_end).where(:message_id => @campaign.group.map{|g| g.id_messages_share_clients}.flatten).find_each  do |call|
        #no se exporta los mensajes anonimos
        next if call.message.nil?
        begin
          row = [call.message.group.campaign.entity.name, call.message.group.campaign.name, call.client.fullname, call.message.name, call.message.call, call.enter, call.enter_listen, call.length, call.bill_duration,  call.hangup_status]
          ivr_to_cdr(YAML.load(call.plivo_call.data)).each{|r| row << r.join("=")}
          csv << row
        rescue
        end
      end

    end
    
    send_data csv_string, :type => "text/csv", :filename => "export_#{session.object_id}.csv", :disposition => 'attachment'
  end

  private
  def ivr_to_cdr(data)
    answers = []
    trans = Parslet::Transform.new do
      rule(:register => simple(:x), :options => subtree(:o), :result => simple(:r)){
        title = ""
        if o[:id]
          title = o[:id]
        elsif o[:audio]
          title = o[:audio]
        elsif o[:decir]
          title = o[:decir]
        end

        answers << [title, r]
        nil
      }
    end
    
    trans.apply(data)
    logger.debug(answers)
    return answers
  end
  
end
