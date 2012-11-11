class NotificationController < ApplicationController
  def index
    @notifications = Notification.order('created_at DESC').paginate :page => params[:page]
    respond_to do |format|
      format.html
    end
  end
end
