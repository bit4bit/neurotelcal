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


class GroupsController < ApplicationController
  skip_before_filter :authenticate_user!, :authorize_admin
  before_filter :require_user_or_operator!
  before_filter :validate_request_owner
  # GET /groups
  # GET /groups.json
  def index
    #activo session[:campaign_id] para saber en cual campana se esta
    if params[:campaign_id]
      @campaign_id = params[:campaign_id].to_i
      session[:campaign_id] = @campaign_id
    else
      @campaign_id = session[:campaign_id]
    end

    @campaign = Campaign.find(@campaign_id)

    @groups = Group.where(:campaign_id => @campaign_id).paginate :page => params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
    @group = Group.find(params[:id])
    @group.campaign_id = session[:campaign_id]

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
    @group = Group.new
    @group.campaign_id = session[:campaign_id]
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @group }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
    @group.campaign_id = session[:campaign_id]
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(params[:group])
    @group.campaign_id = session[:campaign_id]

    respond_to do |format|
      if @group.save
        format.html { redirect_to @group, :notice => 'Group was successfully created.' }
        format.json { render :json => @group, :status => :created, :location => @group }
      else
        format.html { render :action => "new" }
        format.json { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
    @group = Group.find(params[:id])
    @group.campaign_id = session[:campaign_id]

    respond_to do |format|
      if @group.update_attributes(params[:group])
        format.html { redirect_to @group, :notice => 'Group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find(params[:id])
    @group.campaign_id = session[:campaign_id]
    @group.destroy

    respond_to do |format|
      format.html { redirect_to groups_url }
      format.json { head :no_content }
    end
  end

  def status_start
    @group = Group.find(params[:group_id])
    respond_to do |format| 
      if @group.update_column(:status, 'start')
        format.html { redirect_to :action => 'index', :notice => 'Grupo iniciado'}
      else
        format.html {redirect_to :action => 'index' }
      end
      
    end
  end
  
 def status_stop
    @group = Group.find(params[:group_id])
    respond_to do |format|
      if @group.update_column(:status, 'stop')
        format.html { redirect_to :action => 'index', :notice => 'Grupo detenido'}
      else
        format.html {redirect_to :action => 'index' }
      end
      
    end
  end

  private
  def validate_request_owner
    if params[:id] && session[:campaign_id]
      unless Group.where(:id => params[:id], :campaign_id => session[:campaign_id]).exists?
        head :bad_request
      end
    end
    if params[:group_id] && session[:campaign_id]
      unless Group.where(:id => params[:group_id], :campaign_id => session[:campaign_id]).exists?
        head :bad_request
      end
    end
  end
  
end
