# -*- coding: utf-8 -*-
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


# -*- coding: utf-8 -*-
class SessionsController < ApplicationController
  skip_before_filter :authorize

  def new
    render :layout => 'front'
    #session.clear
  end

  def create
    if user = User.authenticate(params[:name], params[:password])
      session[:user_id] = user.id
      session[:monitor_campaign_id] = user.monitor_campaign_id
      session[:monitor] = user.monitor
      session[:admin] = user.admin 
      logger.debug(session)
      if session[:monitor] == true and session[:admin] == false
        redirect_to operators_operator_index_path
      else
        redirect_to campaigns_url
      end
    else
      redirect_to session_url, :alert => "Invalido combinación usuario/contraseña"
    end
  end

  def destroy
    session.clear
    session[:user_id] = nil

    reset_session
    redirect_to login_url, :notice => "Se finalizo el ingreso"
  end
end
