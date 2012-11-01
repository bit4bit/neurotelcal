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
  layout :auto_layout
  protect_from_forgery

  private
  
  def auto_layout
    if session[:admin] == false and session[:monitor] == true
      return "monitoring"
    end
    return "application"    
  end
  
  #Sistema rudimentario de control de acceso
  def authorize_monitor
    url_authorize = Rails.application.routes.recognize_path request.original_url
    #@todo mejorar esto
    url_valids = [
                  {:controller => 'monitor', :action => 'index'},
                  {:controller => 'monitor', :action => 'campaigns_status'},
                  {:controller => 'monitor', :action => 'channels_status'},
                  {:controller => 'monitor', :action => 'cdr'},
                  {:controller => 'sessions', :action => 'new'},
                  {:controller => 'sessions', :action => 'destroy'}
                 ]
    if not url_valids.include?(url_authorize)
      redirect_to login_url, :notice => 'Acceso no autorizado'
    else
      return false
    end
    return true
  end
  
  def authorize
 
    if request.remote_ip == '127.0.0.1' or request.remote_ip == '0.0.0.0' or request.local?
      logger.debug("Direct access to 127.0.0.1")
      return
    end

    #Permisos de servidor plivo
    if not Plivo.where('api_url LIKE ?', '%'+request.remote_ip+'%').empty?
      logger.debug("Direct access to "+request.remote_ip)
      return
    end

    #Permisos session
    if not User.find_by_id(session[:user_id])
      redirect_to login_url, :notice => "Ingrese primero"
      return
    end

    if session[:monitor]
      authorize_monitor
      return
    end
    
    if not session[:admin]
      redirect_to login_url, :notice => "No autorizado/a"
      return
    end

  end
end
