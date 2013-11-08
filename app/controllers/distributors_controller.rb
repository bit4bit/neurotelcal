class DistributorsController < ApplicationController
  # GET /distributors
  # GET /distributors.json
  def index
    if params[:campaign_id]
      @campaign_id = params[:campaign_id].to_i
      session[:campaign_id] = @campaign_id
    else
      @campaign_id = session[:campaign_id]
    end
    @campaign = Campaign.find(@campaign_id)

    @distributors = Distributor.where(:campaign_id => @campaign_id).all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @distributors }
    end
  end

  # GET /distributors/1
  # GET /distributors/1.json
  def show
    @distributor = Distributor.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @distributor }
    end
  end

  # GET /distributors/new
  # GET /distributors/new.json
  def new
    @distributor = Distributor.new
    @plivos = Plivo.where(:campaign_id => session[:campaign_id])
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @distributor }
    end
  end

  # GET /distributors/1/edit
  def edit
    @distributor = Distributor.find(params[:id])
    @plivos = Plivo.where(:campaign_id => session[:campaign_id])
  end

  # POST /distributors
  # POST /distributors.json
  def create
    params[:distributor][:campaign_id] = session[:campaign_id]
    @distributor = Distributor.new(params[:distributor])
    @plivos = Plivo.where(:campaign_id => session[:campaign_id])

    respond_to do |format|
      if @distributor.save
        format.html { redirect_to distributors_path(:campaign_id => session[:campaign_id]), notice: 'Distributor was successfully created.' }
        format.json { render json: @distributor, status: :created, location: @distributor }
      else
        format.html { render action: "new" }
        format.json { render json: @distributor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /distributors/1
  # PUT /distributors/1.json
  def update
    @distributor = Distributor.find(params[:id])
    @plivos = Plivo.where(:campaign_id => session[:campaign_id])

    respond_to do |format|
      if @distributor.update_attributes(params[:distributor])
        format.html { redirect_to @distributor, notice: 'Distributor was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @distributor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /distributors/1
  # DELETE /distributors/1.json
  def destroy
    @distributor = Distributor.find(params[:id])
    @distributor.destroy

    respond_to do |format|
      format.html { redirect_to distributors_url }
      format.json { head :no_content }
    end
  end


  #GET
  def disable
    @distributor = Distributor.find(params[:distributor_id])
    @distributor.active = false
    @distributor.save
    respond_to do |format|
      format.html { redirect_to distributors_url }
      format.json { head :no_content }
    end
  end

  #GET
  def enable
    @distributor = Distributor.find(params[:distributor_id])
    @distributor.active = true
    @distributor.save
    respond_to do |format|
      format.html { redirect_to distributors_url }
      format.json { head :no_content }
    end
  end
  
end
