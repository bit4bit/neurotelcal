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

require 'plivo'
class MessagesController < ApplicationController
  skip_before_filter :authenticate_user!, :authorize_admin
  before_filter :require_user_or_operator!
  before_filter :validate_request_owner
  # GET /messages
  # GET /messages.json
  def index
    #activo session[:campaign_id] para saber en cual campana se esta
    #valida que
   
    if params[:group_id]
      group_id = params[:group_id]
      group = Group.find(group_id)
      @campaign_id = group.campaign_id
      session[:campaign_id] = group.campaign_id
      session[:group_id] = group_id
    else
      group_id = session[:group_id]
      @campaign_id = session[:campaign_id]
    end

    @group = Group.find(group_id)
    @campaign = Campaign.find(@campaign_id)
    @messages = Message.where('group_id' => group_id, :anonymous => false).paginate :page => params[:page], :order => 'created_at desc'


    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @messages }
    end
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
    @message = Message.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @message }
    end
  end

  # GET /messages/new
  # GET /messages/new.json
  def new
    @message = Message.new
    @message.group_id = session[:group_id]
    @resources = @message.group.campaign.resource.all
    @resource = Resource.new(params[:resource])
    @resource.campaign_id = session[:campaign_id]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @message }
    end
  end

  # GET /messages/1/edit
  def edit
    @message = Message.where(:group_id => session[:group_id]).find(params[:id])
    @resources = @message.group.campaign.resource.all
    @resource = Resource.new(params[:resource])
    @resource.campaign_id = session[:campaign_id]

  end

  # POST /messages
  # POST /messages.json
  def create
    @message = Message.new(params[:message])
    @message.group_id = session[:group_id]
    @resources = @message.group.campaign.resource.where(:type_file => "audio").all
    @resource = Resource.new(params[:resource])
    @resource.campaign_id = session[:campaign_id]

    respond_to do |format|
      if @message.save
        format.html { redirect_to messages_path(:group_id => session[:group_id]), :notice => 'Message was successfully created.' }
        format.json { render :json => @message, :status => :created, :location => @message }
      else
        format.html { render :action => "new" }
        format.json { render :json => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /messages/1
  # PUT /messages/1.json
  def update
    @message = Message.find(params[:id])
    @message.group_id = session[:group_id]
    @resources = @message.group.campaign.resource.all
    @resource = Resource.new(params[:resource])
    @resource.campaign_id = session[:campaign_id]

    respond_to do |format|
      if @message.update_attributes(params[:message])
        format.html { redirect_to @message, :notice => 'Message was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    @message = Message.find(params[:id])
    @message.destroy

    respond_to do |format|
      format.html { redirect_to messages_url }
      format.json { head :no_content }
    end
  end

 
  #Muestra formulario para 
  #realizar llamada
  def call_client
    @campaign = Campaign.find(session[:campaign_id])
    @message = Message.find(params[:id])
  end

  def docall_client
    @message = Message.find(params[:message][:id])
    @campaign = Campaign.find(session[:campaign_id])
    @client = Client.new()
    @client.group_id = session[:group_id]
    @client.campaign_id = session[:campaign_id]
    @client.phonenumber = params[:phonenumber]
    @client.fullname = params[:phonenumber].to_s + ':prueba'
    @client.save!
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
      @test_message = @message.dup
      @test_message.id = nil
      @test_message.anonymous = true
      @test_message.save(:validate => false)
      @campaign.call_client!(@client, @test_message)
    rescue ::PlivoChannelFull => e
      flash[:error] = 'No hay canales disponibles'
    rescue ::PlivoCannotCall => e
      flash[:error] = e.message
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

  #PRIVATE
  private
  def validate_request_owner
    if params[:group_id] && session[:campaign_id]
      unless Group.where(:id => params[:group_id], :campaign_id => session[:campaign_id]).exists?
        head :bad_request
        return false
      end
    end
    if params[:id] && session[:group_id]
      unless Message.where(:id => params[:id], :group_id => session[:group_id]).exists?
        head :bad_request
        return false
      end
    end
    
    if params[:message_id] && session[:group_id]
      unless Message.where(:id => params[:message_id], :group_id => session[:group_id]).exists?
        head :bad_request
        return false
      end
    end
    
  end
 
end



