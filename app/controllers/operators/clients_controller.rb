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
require 'csv'

class Operators::ClientsController < Operators::ApplicationController
  # GET /clients
  # GET /clients.json
  def index
    if params[:group_id]
      group_id = params[:group_id]
      session[:group_id] = group_id
    else
      group_id = session[:group_id]
    end
    
    @campaign_id = session[:campaign_id]

    @campaign = Campaign.find(@campaign_id)

    if params[:search]
      @clients = Client.where(:campaign_id => @campaign_id, :group_id => group_id).where('fullname LIKE ? OR phonenumber LIKE ?', "%%#{params[:search]}%%", "%%#{params[:search]}").paginate(:page => params[:page])
    else
      @clients = Client.where(:campaign_id => @campaign_id, :group_id => group_id).paginate(:page => params[:page]).order(created_at: :asc)
    end

 
    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @clients }
    end
  end

  # GET /clients/1
  # GET /clients/1.json
  def show
    @client = Client.find(params[:id])
    @client.campaign_id = session[:campaign_id]

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @client }
    end
  end

  # GET /clients/new
  # GET /clients/new.json
  def new
    @client = Client.new
    @client.campaign_id = session[:campaign_id]
    @group = Group.where(:id => session[:group_id], :campaign_id => session[:campaign_id]).first
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @client }
    end
  end

  # GET /clients/1/edit
  def edit
    @client = Client.find(params[:id])
    @client.campaign_id = session[:campaign_id]
    @group = Group.where(:id => session[:group_id], :campaign_id => session[:campaign_id]).first
  end

  # POST /clients
  # POST /clients.json
  def create
    @client = Client.new(params[:client])
    @client.campaign_id = session[:campaign_id]
    @group = Group.where(:id => session[:group_id], :campaign_id => session[:campaign_id]).first
    @client.group_id = session[:group_id]
    respond_to do |format|
      if @client.save
        format.html { redirect_to operators_clients_path, :notice => 'Client was successfully created.' }
        format.json { render :json => @client, :status => :created, :location => operators_clients_path }
      else
        format.html { render :action => "new" }
        format.json { render :json => @client.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /clients/1
  # PUT /clients/1.json
  def update
    @client = Client.find(params[:id])
    @client.campaign_id = session[:campaign_id]
    @groups = Group.all.map {|g| [g.name, g.id]}
    @client.group_id = session[:group_id]
    respond_to do |format|
      if @client.update_attributes(params[:client])
        format.html { redirect_to @client, :notice => 'Client was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @client.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /clients/1
  # DELETE /clients/1.json
  def destroy
    @client = Client.find(params[:id])
    @client.campaign_id = session[:campaign_id]
    @client.destroy

    respond_to do |format|
      format.html { redirect_to operators_clients_url }
      format.json { head :no_content }
    end
  end

  def new_upload_massive
    @group = Group.where(:campaign_id => session[:campaign_id], :id => session[:group_id]).first
    respond_to do |format|
      format.html 
    end
  end
  
  def create_upload_massive
    @group = Group.where(:campaign_id => session[:campaign_id], :id => session[:group_id]).first

    if params[:list_clients]
      flash[:notice] = I18n.t('sended_job_upload_clients')
      require 'fileutils'
      require 'tempfile'
      newfile = Tempfile.new('client_massive')
      FileUtils.cp params[:list_clients].tempfile.path.to_s, newfile.path

      file = {
        :ext => File.extname(params[:list_clients].original_filename),
        :path => newfile.path
      }

      Delayed::Job.enqueue(::CDRJob.new(file, session[:user_id], session[:campaign_id], session[:group_id]), :queue => 'clients_import')
      

    end
    
    respond_to do |format|
      format.html { render :action => 'new_upload_massive'}
    end
  end
  
end
