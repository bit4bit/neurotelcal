class MessageCalendarsController < ApplicationController
  skip_before_filter :authenticate_user!, :authorize_admin
  before_filter :require_user_or_operator!
  before_filter :validate_request_owner

  # GET /message_calendars
  # GET /message_calendars.json
  def index
    @message = Message.find(params[:message_id])
    @message_calendars = MessageCalendar.where(:message_id => params[:message_id]).paginate(:page=>params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @message_calendars }
    end
  end

  # GET /message_calendars/1
  # GET /message_calendars/1.json
  def show
    @message_calendar = MessageCalendar.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @message_calendar }
    end
  end

  # GET /message_calendars/new
  # GET /message_calendars/new.json
  def new
    @message_calendar = MessageCalendar.new(:message_id => params[:message_id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @message_calendar }
    end
  end

  # GET /message_calendars/1/edit
  def edit
    @message_calendar = MessageCalendar.find(params[:id])
  end

  # POST /message_calendars
  # POST /message_calendars.json
  def create
    @message_calendar = MessageCalendar.new(params[:message_calendar])

    respond_to do |format|
      if @message_calendar.save
        format.html { redirect_to message_calendars_path(:message_id => @message_calendar.message.id), notice: 'Message calendar was successfully created.' }
        format.json { render json: @message_calendar, status: :created, location: @message_calendar }
      else
        format.html { render action: "new" }
        format.json { render json: @message_calendar.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /message_calendars/1
  # PUT /message_calendars/1.json
  def update
    @message_calendar = MessageCalendar.find(params[:id])

    respond_to do |format|
      if @message_calendar.update_attributes(params[:message_calendar])
        format.html { redirect_to message_calendars_path(:message_id => @message_calendar.message.id), notice: 'Message calendar was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @message_calendar.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /message_calendars/1
  # DELETE /message_calendars/1.json
  def destroy
    @message_calendar = MessageCalendar.find(params[:id])
    @message_calendar.destroy

    respond_to do |format|
      format.html { redirect_to :action => :index, :message_id => @message_calendar.message }
      format.json { head :no_content }
    end
  end

  private
  def validate_request_owner
    if params[:message_id] && session[:campaign_id]
      unless Message.where(:id => params[:message_id], :group_id => Campaign.find(session[:campaign_id]).group.all).exists?

        head :bad_request
      end
    end
    
    if params[:id] && session[:campaign_id]
      unless MessageCalendar.where(:id => params[:id], :message_id => Campaign.find(session[:campaign_id]).group.where(:id => session[:group_id]).map{|g| g.message.all}.flatten).exists?
        head :bad_request
      end
    end
    
  end
  
end



