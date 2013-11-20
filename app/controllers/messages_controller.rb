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


class MessagesController < ApplicationController
  skip_before_filter :authenticate_user!, :authorize_admin
  before_filter :require_user_or_operator!

  # GET /messages
  # GET /messages.json
  def index
    #activo session[:campaign_id] para saber en cual campana se esta
    
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

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @message }
    end
  end

  # GET /messages/1/edit
  def edit
    @message = Message.where(:group_id => session[:group_id]).find(params[:id])
    @resources = @message.group.campaign.resource.all
  end

  # POST /messages
  # POST /messages.json
  def create
    @message = Message.new(params[:message])
    @message.group_id = session[:group_id]
    @resources = @message.group.campaign.resource.all

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
end
