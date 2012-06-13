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
  before_filter :authorize
  protect_from_forgery

  private
  

  def authorize
    if request.remote_ip == '127.0.0.1'
      return
    end

    #Permisos de servidor plivo
    if not Plivo.where('api_url LIKE ?', '%'+request.remote_ip+'%').empty?
      return
    end
    
    #Permisos session
    if not User.find_by_id(session[:user_id])
      redirect_to login_url, :notice => "Ingrese primero"
    end
  end
end
