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

  # GET /plivos
  # GET /plivos.json
  def index
    @plivos = Plivo.all
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }
    print @campaigns
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
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @plivo }
    end
  end

  # GET /plivos/1/edit
  def edit
    @plivo = Plivo.find(params[:id])
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }
  end

  # POST /plivos
  # POST /plivos.json
  def create
    @plivo = Plivo.new(params[:plivo])
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }

    respond_to do |format|
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
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }

    respond_to do |format|
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


  def get_digits_client
    logger.debug('get_digits')
    logger.debug(params)

    @plivocall = PlivoCall.where(:uuid => params["id"]).first
    @call_sequence = @plivocall.call_sequence
    
    @plivocall.status = params['CallStatus']
    #almacena resultado de esta peticion
    @call_sequence[@plivocall.step-1][:result] = params['Digits']
    @plivocall.data = @call_sequence.to_yaml
    @plivocall.save


    @plivo = @plivocall.plivo
    #actualiza estado de llamada
    call = Call.find(@plivocall.call_id)
    if call
      call.enter_listen = Time.now
      call.status = @plivocall.status
      call.save
    end


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
    
    @plivocall = PlivoCall.where(:uuid => params["ALegRequestUUID"]).first
    @call_sequence = @plivocall.call_sequence
    #actualiza estado
    @plivocall.status = "answered"
    @plivocall.save

    @plivo = @plivocall.plivo
    #actualiza estado de llamada
    call = Call.find(@plivocall.call_id)
    if call
      call.enter_listen = Time.now
      call.status = @plivocall.status
      call.save
    end

    logger.debug('Trying first plivo from campaign to url ' + @plivo.app_url)
    respond_to do |format|
      format.xml
    end
  end

  def hangup_client
    logger.debug('hangup')
    #logger.debug('hangup')
    plivocall = PlivoCall.where(:uuid => params["RequestUUID"]).first_or_create
    plivocall.status = params["CallStatus"]

    #@todo mejorar esto un campo y listo
    plivocall.hangup_enumeration = params["HangupCause"] if params["HangupCause"]
    plivocall.end = true
    plivocall.save
    logger.debug(params)
    
    case params["CallStatus"]
    when 'completed'
    end

    #se notifica que porfin se contesto

    if Call.where(:id => plivocall.call_id).exists?
      call = Call.find(plivocall.call_id)
      call.terminate = Time.now
      call.completed_p = true
      
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
      call.save
    end



    respond_to do |format|
      format.xml
    end
  end

  def ringing_client
    logger.debug('ringing')
    logger.debug(params)

    plivocall = PlivoCall.where(:uuid => params["RequestUUID"]).first_or_create
    plivocall.status = params["CallStatus"]
    plivocall.save

    #se notifica que porfin se contesto
    call = Call.find(plivocall.call_id)
    call.status = plivocall.status
    call.save

    respond_to do |format|
      format.xml
    end
  end

  def docall_client
    @campaign = Campaign.find(session[:campaign_id])
    @client = Client.find(params[:id])
    params[:message][:id] = nil
    params[:message][:name] = I18n.t('defaults.direct_message') + @client.object_id.to_s
    params[:message][:call] = Time.now
    params[:message][:call_end] = Time.now
    params[:message][:anonymous] = true
    @message = Message.new(params[:message])
    @message.group_id = @client.group.id


    if @message.valid?
      @message.save
      
    begin
      @campaign.call_client(@client, @message)
    rescue PlivoCannotCall => e
      flash[:notice] = 'No hay canales disponibles'
    rescue Errno::ECONNREFUSED => e
      flash[:notice] = 'No se pudo conectar a plivo en %s' % plivo.api_url
    rescue Exception => e
      logger.debug(e)
      flash[:notice] = "error:" + e.class.to_s
    end
     
      flash[:notice] = ''
      
      
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
