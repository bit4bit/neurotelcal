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
class Operators::OperatorController < Operators::ApplicationController
  before_filter :validate_campaign

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
        format.html { redirect_to operators_operator_index_path, :notice => 'Group was successfully created.' }
        format.json { render :json => @group, :status => :created, :location => operators_operator_index_path}
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
        format.html { redirect_to operators_operator_index_path, :notice => 'Group was successfully updated.' }
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
      format.html { redirect_to operators_operator_index_path }
      format.json { head :no_content }
    end
  end

  private

  #@todo si esto falla deberia quedar registro de la ip
  #y el usuario que intento
  def validate_campaign
    if params[:id]
      unless Group.where(:campaign_id => session[:campaign_id], :id => params[:id]).exists?
        flash[:error] = 'Group invalido para campana actual'

        redirect_to operators_operator_index_path
      end
    end
    
  end
  
  end
