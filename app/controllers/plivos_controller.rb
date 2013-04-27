# Copyright (C) 2012 Bit4Bit <bit4bit@riseup.net>
#
# This file is part of NeuroTelCal
#
# This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.


require 'plivohelper'
    
class PlivosController < ApplicationController
  skip_before_filter :verify_authenticity_token

  # GET /plivos
  # GET /plivos.json
  def index
    @plivos = Plivo.order('priority ASC').all
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @plivos }
    end
  end

  # GET /plivos/1
  # GET /plivos/1.json
  def show
    @plivo = Plivo.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @plivo }
    end
  end

  # GET /plivos/new
  # GET /plivos/new.json
  def new
    @plivo = Plivo.new
    @campaigns = Campaign.all

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @plivo }
    end
  end

  # GET /plivos/1/edit
  def edit
    @plivo = Plivo.find(params[:id])
    @campaigns = Campaign.all
  end

  # POST /plivos
  # POST /plivos.json
  def create
    @plivo = Plivo.new(params[:plivo])
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }

    respond_to do |format|
      params[:plivo][:extra_dial].strip!
      params[:plivo][:gateways].strip!
      if @plivo.save
        format.html { redirect_to @plivo, :notice => 'Plivo was successfully created.' }
        format.json { render :json => @plivo, :status => :created, :location => @plivo }
      else
        format.html { render :action => "new" }
        format.json { render :json => @plivo.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /plivos/1
  # PUT /plivos/1.json
  def update
    @plivo = Plivo.find(params[:id])
    @campaigns = Campaign.all

    respond_to do |format|
      params[:plivo][:extra_dial].strip!
      params[:plivo][:gateways].strip!
      if @plivo.update_attributes(params[:plivo])
        format.html { redirect_to @plivo, :notice => 'Plivo was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @plivo.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /plivos/1
  # DELETE /plivos/1.json
  def destroy
    @plivo = Plivo.find(params[:id])
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }
    @plivo.destroy

    respond_to do |format|
      format.html { redirect_to plivos_url }
      format.json { head :no_content }
    end
  end

  #actualiza cuando se contacta el cliente
  #se espera id => de plivo call
  def contact_client
    logger.debug('contact_client')
    logger.debug(params)
    cached = true
    #@todo esto es una aberracion pero funciona..
    #se almacena estado de cuelgue de la llamada
    if params['DialBLegHangupCause']
      @plivocall = Rails.cache.read(:plivocall_id => params['id'])
      if @plivocall.nil?
        @plivocall = PlivoCall.find(params['id'])
        cached = false
      end
      
      @call_sequence = @plivocall.call_sequence
      @call_sequence[@plivocall.step-1][:result] = params['DialBLegHangupCause']
      @plivocall.data = @call_sequence.to_yaml
      @plivocall.save(:validate => false) unless cached
      #unless @plivocall.save(:validate => false)
      #  logger.error('plivos: error fallo actualizar digitos de plivo call %d digito %s' % [@plivocall.id, params['Digits']])
      #end
      Rails.cache.write({:plivocall_id => params['id']}, @plivocall, :expires_in => 60.seconds)
    end
    
  end
  
  #Actualiza sequencia de llamada
  def continue_sequence_client
    logger.debug('continue_sequence_client')
    logger.debug(params)
    cached = true
    @plivocall = Rails.cache.read(:plivocall_id => params["AccountSID"])
    if @plivocall.nil?
      @plivocall = PlivoCall.where(:id => params["AccountSID"]).first
      cached = false
    end
    
    @call_sequence = @plivocall.call_sequence
    @plivo = @plivocall.plivo
    #actualiza estado de llamada
    call = Rails.cache.read(:call_id => params["AccountSID"])
    call = Call.find(@plivocall.call_id) if call.nil?
    call.client.update_column(:calling, true)
    call.enter_listen = Time.now
    call.status = @plivocall.status
    call.save unless cached
    Rails.cache.write({:call_id => @plivocall.call_id}, call, :expires_in => 60.seconds)

    respond_to do |format|
      format.xml { render 'answer_client' }
    end    
  end
  
  def get_digits_client
    logger.debug('get_digits')
    logger.debug(params)
    salir = false
    cached = true
    @plivocall = Rails.cache.read(:plivocall_id => params["AccountSID"])
    if @plivocall.nil?
      @plivocall = PlivoCall.where(:id => params["AccountSID"]).first
      cached = false
    end
      


    @call_sequence = @plivocall.call_sequence
    @plivocall.status = params['CallStatus']
    #almacena resultado de esta peticion
    @call_sequence[@plivocall.step-1][:result] = params['Digits']
    @plivocall.data = @call_sequence.to_yaml
    Rails.cache.write({:plivocall_id => params["AccountSID"]}, @plivocall, :expires_in => 60.seconds)
    @plivocall.save(:validate => false) unless cached
    #@trash
    #unless @plivocall.save(:validate => false)
     # logger.error('plivos: error fallo actualizar digitos de plivo call %d digito %s' % [@plivocall.id, params['Digits']])
    #end
    


    @plivo = @plivocall.plivo
    #actualiza estado de llamada
    call = Rails.cache.read(:call_id => @plivocall.call_id)
    call = Call.find(@plivocall.call_id) if call.nil?
    
    call.client.update_column(:calling, true)
    call.enter_listen = Time.now
    call.status = @plivocall.status
    call.save unless cached
    Rails.cache.write({:call_id => @plivocall.call_id}, call, :expires_in => 60.seconds)


    respond_to do |format|
      format.xml { render 'answer_client' }
    end
  end
  
  #Muestra formulario para 
  #realizar llamada
  def call_client
    @campaign = Campaign.find(session[:campaign_id])
    @client = Client.find(params[:id])
    @message = Message.new(params[:message])
  end
  
  def answer_client
    logger.debug('answer')
    logger.debug(params)
    salir = false
    cached = true
    @plivocall = Rails.cache.read(:plivocall_id => params["AccountSID"])
    if @plivocall.nil?
      @plivocall = PlivoCall.where(:id => params["AccountSID"]).first 
      cached = false
    end
    

    @call_sequence = @plivocall.call_sequence
    #actualiza estado
    @plivocall.uuid = params["CallUUID"]
    @plivocall.status = "answered"
    @plivocall.save unless cached
    Rails.cache.write({:plivocall_id => params["AccountSID"]}, @plivocall, :expires_in => 60.seconds)

    #@trash
    @plivo = @plivocall.plivo
    #actualiza estado de llamada
    call = Rails.cache.read(:call_id => @plivocall.call_id)
    if call.nil?
      call = Call.find(@plivocall.call_id)
      logger.debug('process: omiting cache')
    end
    
    call.enter_listen = Time.now
    call.status = @plivocall.status
    call.client.update_column(:calling, true)
    call.save unless cached
    Rails.cache.write({:call_id => @plivocall.call_id}, call, :expires_in => 60.seconds)
    #@trash
    #logger.debug('Trying first plivo from campaign to url ' + @plivo.app_url)
    respond_to do |format|
      format.xml
    end
  end

  def hangup_client
    logger.debug('hangup_client:')
    logger.debug(params)


    plivocall = Rails.cache.read(:plivocall_id => params["AccountSID"])
    if plivocall.nil?
      plivocall = PlivoCall.where(:id => params["AccountSID"]).first      
    else
      Rails.cache.delete(:plivocall_id => params["AccountSID"])
    end



    plivocall.uuid = params["CallUUID"]
    plivocall.status = params["CallStatus"]

    plivocall.hangup_enumeration = params["HangupCause"] if params["HangupCause"]
    plivocall.bill_duration = params["BillDuration"] if params["BillDuration"]
    plivocall.end = true
    plivocall.save


    
    call = Rails.cache.read(:call_id => plivocall.call_id)
    if call.nil?
      call = Call.find(plivocall.call_id)
    else
      Rails.cache.delete(:call_id => plivocall.call_id)
    end
   
    call.terminate = Time.now
    call.completed_p = true
    call.data = plivocall.data
    
    if plivocall.answered?
      call.terminate_listen = Time.now
    else
      call.terminate_listen = nil
    end
    
    call.status = plivocall.status
    call.hangup_enumeration = plivocall.hangup_enumeration
    
    if call.terminate_listen and call.enter_listen
      call.length = call.terminate_listen - call.enter_listen
    else
      call.length = 0
    end

    call.bill_duration = plivocall.bill_duration
    call.save

   
    #se notifica que porfin se contesto
    #ya no es necesario el cliente por que se recibio estado que se queria
    if PlivoCall::ANSWER_ENUMERATION.include?(plivocall.hangup_enumeration) and not call.message.anonymous
      call.client.update_column(:callable, false)
    else
      call.client.increment!(:calls_faileds)
    end

    if PlivoCall::INVALID_ENUMERATION.include?(call.hangup_enumeration) and not call.message.anonymous
      call.client.update_column(:error, true)
      call.client.update_column(:error_msg, 'INVALID')
    end

    
    #se actualiza prioridad a cliente para marcacion
    call.client.update_column(:last_call_at, Time.now())
    call.client.update_priority_by_hangup_cause(call.hangup_enumeration)
    call.client.update_column(:calling, false)
    call.client.increment!(:calls)
    #se da por sentado que no se necesita mas el plivo

    respond_to do |format|
      format.xml
    end
  end

  def ringing_client
    logger.debug('ringing')
    logger.debug(params)
    

    plivocall = PlivoCall.where(:id => params["AccountSID"]).first
    plivocall.uuid = params["CallUUID"]
    plivocall.status = params["CallStatus"]
    plivocall.save
    
    #se notifica que porfin se contesto
    call = Call.find(plivocall.call_id)
    call.status = plivocall.status
    call.client.update_column(:calling, true)
    call.save


    #se guarda cache
    Rails.cache.write({:plivocall_id => params["AccountSID"]}, plivocall, :expires_in => 60.seconds)
    Rails.cache.write({:call_id => plivocall.call_id}, call, :expires_in => 60.seconds)

    respond_to do |format|
      format.xml
    end
  end

  def docall_client
    @campaign = Campaign.find(session[:campaign_id])
    @client = Client.find(params[:id])
    flash[:notice] = '' unless flash[:notice].nil?
    flash[:error] = '' unless flash[:notice].nil?

    if @client.calling?
      flash[:error] = 'Ya hay una en proceso'
      return respond_to do |format|
        format.html { render :action => 'call_client' }
      end
    end
    

    begin
      params[:message][:id] = nil
      params[:message][:name] = I18n.t('defaults.direct_message') + @client.object_id.to_s
      params[:message][:call] = Time.now
      params[:message][:call_end] = Time.now
      params[:message][:anonymous] = true
      params[:message][:retries] = 1
      @message = Message.new(params[:message])
      @message.group_id = @client.group.id
      @message.save(:validate => false)
      @message.reload
      @campaign.call_client!(@client, @message)
    rescue PlivoCannotCall => e
      flash[:notice] = 'No hay canales disponibles:' + e.message
    rescue Errno::ECONNREFUSED => e
      flash[:error] = 'No se pudo conectar al/los plivo de la campana'
    rescue Exception => e
      logger.debug(e)
      flash[:error] = "error:" + e.class.to_s
    end



    respond_to do |format|
      format.html { render :action => 'call_client' }
    end
  end

  #++++++++REPORTES
  def report
    @plivocalls = PlivoCall.paginate :page => params[:page], :order => "created_at DESC"
  end

end
