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


class ApplicationController < ActionController::Base
  before_filter :authenticate_user!
  before_filter :authorize_admin
  layout :auto_layout
  protect_from_forgery

  private
  
  def auto_layout
    if operators_user_signed_in?
      return "operator"
    end

    if !user_signed_in?
      return "login"
    end
    
    if session[:admin] == false and session[:monitor] == true
      return "monitoring"
    end
    
    return "application"    
  end
  
  
  def authorize_admin
    if user_signed_in?
      if current_user.monitor
        sign_out current_user
        session.clear
        redirect_to new_operators_user_session_path
      end
    end
  end

  protected
  def require_user_or_operator!
    unless user_signed_in? or operators_user_signed_in?
      redirect_to root_path, :alert => "Access denied"
    end
  end
  
end







