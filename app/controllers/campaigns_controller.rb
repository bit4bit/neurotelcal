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


class CampaignsController < ApplicationController
  # GET /campaigns
  # GET /campaigns.json
  def index
    @campaigns = Campaign.paginate :page => params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @campaigns }
    end
  end

  # GET /campaigns/1
  # GET /campaigns/1.json
  def show
    @campaign = Campaign.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @campaign }
    end
  end

  # GET /campaigns/new
  # GET /campaigns/new.json
  def new
    @campaign = Campaign.new
    @entities = Entity.all.map { |u| [u.name, u.id]}
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @campaign }
    end
  end

  # GET /campaigns/1/edit
  def edit
    @campaign = Campaign.find(params[:id])
    @entities = Entity.all.map { |u| [u.name, u.id]}
  end

  # POST /campaigns
  # POST /campaigns.json
  def create
    @campaign = Campaign.new(params[:campaign])
    @entities = Entity.all.map { |u| [u.name, u.id]}
    respond_to do |format|
      if @campaign.save
        format.html { redirect_to @campaign, :notice => 'Campaign was successfully created.' }
        format.json { render :json => @campaign, :status => :created, :location => @campaign }
      else
        format.html { render :action => "new" }
        format.json { render :json => @campaign.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /campaigns/1
  # PUT /campaigns/1.json
  def update
    @campaign = Campaign.find(params[:id])


    respond_to do |format|
      if @campaign.update_attributes(params[:campaign])

        if @campaign.start?
          Delayed::Job.enqueue ::CampaignJob.new(@campaign.id), :queue => @campaign.id
        end

        format.html { redirect_to @campaign, :notice => 'Campaign was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @campaign.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /campaigns/1
  # DELETE /campaigns/1.json
  def destroy
    @campaign = Campaign.find(params[:id])
    @campaign.destroy

    respond_to do |format|
      format.html { redirect_to campaigns_url }
      format.json { head :no_content }
    end
  end
end
