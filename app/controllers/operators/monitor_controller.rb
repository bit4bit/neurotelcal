
class Operators::MonitorController < Operators::ApplicationController

  def index
  end

  def cdr
    messages = Message.where(:group_id => Group.where(:campaign_id => session[:campaign_id])).all
    
    @calls = Call.paginate :page => params[:page], :conditions => ["message_id IN (?) ", messages]
    respond_to do |format|
      format.html
    end
  end
  
  def campaigns_status
    @campaigns = Campaign.where(:id => session[:campaign_id])
    
    
    respond_to do |format|
      format.html { render :layout => nil }
      format.json { render :json => @campaigns }
      format.xml { render :xml => @campaigns }
    end
  end

  def channels_status
    if session[:monitor]
      messages = Message.where(:group_id => Group.where(:campaign_id => session[:monitor_campaign_id])).select('id').all
      @calls = Call.where(:terminate => nil, :message_id => messages)
    else
        @calls = Call.where(:terminate => nil)      
    end

    respond_to do |format|
      format.html { render :layout => nil}
      format.json { render :json => @calls }
    end
  end

end
