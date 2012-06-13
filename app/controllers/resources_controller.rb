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


class ResourcesController < ApplicationController

  #Valores por defecto
  def initialize(*args)
    @options_for_type = [['Audio','audio'],['Documento','documento']]
    super(*args)
  end

  # GET /resources
  # GET /resources.json
  def index

    #activo session[:campaign_id] para saber en cual campana se esta
    if params[:campaign_id]
      @campaign_id = params[:campaign_id].to_i
      session[:campaign_id] = @campaign_id
    else
      @campaign_id = session[:campaign_id]
    end
    @resources = Resource.where(:campaign_id => @campaign_id).paginate :page => params[:page], :order => 'created_at DESC'
    @campaign = Campaign.find(@campaign_id)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @resources }
    end
  end

  # GET /resources/1
  # GET /resources/1.json
  def show
    @resource = Resource.find(params[:id])
    @resource.campaign_id = session[:campaign_id]

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @resource }
    end
  end

  # GET /resources/new
  # GET /resources/new.json
  def new
    @resource = Resource.new(params[:resource])
    @resource.campaign_id = session[:campaign_id]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @resource }
    end
  end

  # GET /resources/1/edit
  def edit
    @resource = Resource.find(params[:id])
    @resource.campaign_id = session[:campaign_id]
  end

  # POST /resources
  # POST /resources.json
  def create
    @resource = Resource.new(params[:resource])
    @resource.campaign_id = session[:campaign_id]

    respond_to do |format|
      if @resource.save
        format.html { redirect_to @resource, :notice => 'Resource was successfully created.' }
        format.json { render :json => @resource, :status => :created, :location => @resource }
      else
        format.html { render :action => "new" }
        format.json { render :json => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /resources/1
  # PUT /resources/1.json
  def update
    @resource = Resource.find(params[:id])
    @resource.campaign_id = session[:campaign_id]

    respond_to do |format|
      aresource = Resource.find(params[:id])
      if @resource.update_attributes(params[:resource])

        #borra archivo anterir
        if aresource.file != @resource.file
          File.unlink(aresource.file) if File.exists? aresource.file
        end

        format.html { redirect_to @resource, :notice => 'Resource was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /resources/1
  # DELETE /resources/1.json
  def destroy
    @resource = Resource.find(params[:id])
    @resource.destroy

    respond_to do |format|
      format.html { redirect_to resources_url }
      format.json { head :no_content }
    end
  end
end
