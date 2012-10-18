class MonitorController < ApplicationController
  def index
  end

  def campaigns_status
    @campaigns = Campaign.all
    respond_to do |format|
      format.html { render :layout => nil }
      format.json { render :json => @campaigns }
      format.xml { render :xml => @campaigns }
    end
  end

  def channels_status
    @calls = Call.where(:terminate => nil)
    respond_to do |format|
      format.html { render :layout => nil}
      format.json { render :json => @calls }
    end
  end
end
