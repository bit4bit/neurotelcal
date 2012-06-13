class CalendarsController < ApplicationController
  # GET /calendars
  # GET /calendars.json
  def index
    #activo session[:campaign_id] para saber en cual campana se esta
    if params[:campaign_id]
      @campaign_id = params[:campaign_id].to_i
      session[:campaign_id] = @campaign_id
    else
      @campaign_id = session[:campaign_id]
    end

    @campaign = Campaign.find(@campaign_id)

    @calendars = Calendar.where(:campaign_id => @campaign_id).paginate :page => params[:page]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @calendars }
    end
  end

  # GET /calendars/1
  # GET /calendars/1.json
  def show
    @calendar = Calendar.find(params[:id])
    @calendar.campaign_id = session[:campaign_id]

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @calendar }
    end
  end

  # GET /calendars/new
  # GET /calendars/new.json
  def new
    @calendar = Calendar.new
    @calendar.campaign_id = session[:campaign_id]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @calendar }
    end
  end

  # GET /calendars/1/edit
  def edit
    @calendar = Calendar.find(params[:id])
    @calendar.campaign_id = session[:campaign_id]

  end

  # POST /calendars
  # POST /calendars.json
  def create
    @calendar = Calendar.new(params[:calendar])
    @calendar.campaign_id = session[:campaign_id]

    respond_to do |format|
      if @calendar.save
        format.html { redirect_to @calendar, :notice => 'Calendar was successfully created.' }
        format.json { render :json => @calendar, :status => :created, :location => @calendar }
      else
        format.html { render :action => "new" }
        format.json { render :json => @calendar.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /calendars/1
  # PUT /calendars/1.json
  def update
    @calendar = Calendar.find(params[:id])
    @calendar.campaign_id = session[:campaign_id]

    respond_to do |format|
      if @calendar.update_attributes(params[:calendar])
        format.html { redirect_to @calendar, :notice => 'Calendar was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @calendar.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /calendars/1
  # DELETE /calendars/1.json
  def destroy
    @calendar = Calendar.find(params[:id])
    @calendar.campaign_id = session[:campaign_id]
    @calendar.destroy

    respond_to do |format|
      format.html { redirect_to calendars_url }
      format.json { head :no_content }
    end
  end
end
