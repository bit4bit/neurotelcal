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


#Herramientas, o acciones utiles de neurotelcal:
# * Importacion de CDRs desde sqlite del servider
# * Importacion de CSV enviado
class ToolsController < ApplicationController

  #GET#
  def new_import_cdr
    respond_to do |format|
      format.html
    end
    
  end
  
  #POST
  def create_import_cdr
    #Importar desde un archivo sqlite local

    #@todo distinguir entre CSV y SQLITE
    if not params[:path_cdr].nil? and File.exists?(params[:path_cdr])
      CdrSqlite.establish_connection(:adapter => 'sqlite3', :database => params[:path_cdr_sqlite])
      flash[:notice] = 'Find ' + CdrSqlite.all.count.to_s + ' registers on sqlite3 db'
      tinit = Time.now
      total_imported = 0
      import_to_cdr(CdrSqlite.all)
      duration = Time.now - tinit
      flash[:notice] += ".Imported " + total_imported.to_s + ' with duration of ' + duration.to_s + ' secs.'
    end
    
    if not params[:upload_cdr].nil?
      header = params[:upload_cdr].tempfile.read(15); params[:upload_cdr].tempfile.seek(0);
      #prueba si sqlite
      cdrs = nil
      if header == 'SQLite format 3'
        CdrSqlite.establish_connection(:adapter => 'sqlite3', :database => params[:upload_cdr].tempfile)
        cdrs = CdrSqlite.all
      else
        flash[:error] = 'Not Sqlite'
      end
      
      if cdrs
        flash[:notice] = 'Find ' + cdrs.count.to_s + ' registers on sqlite3 db'
        tinit = Time.now
        total_imported = import_to_cdr(cdrs)
        duration = Time.now - tinit
        flash[:notice] += ".Imported " + total_imported.to_s + ' with duration of ' + duration.to_s + ' secs.'
      end
    end
    
    
    respond_to do |format|
      format.html { render :action => 'new_import_cdr' }
    end
  end
  
  private
  def import_to_cdr(cdrs)
    total_imported = 0
    Cdr.transaction do
      cdrs.each do |cdrFS|
        next if Cdr.where(:uuid => cdrFS.uuid).exists?
        
        cdr = Cdr.new(:caller_id_name => cdrFS.caller_id_name,
                      :caller_id_number =>  cdrFS.caller_id_number,
                      :destination_number => cdrFS.destination_number,
                      :context => cdrFS.context,
                      :start_stamp => cdrFS.start_stamp,
                      :answer_stamp => cdrFS.answer_stamp,
                      :end_stamp => cdrFS.end_stamp,
                      :duration => cdrFS.duration,
                      :billsec => cdrFS.billsec,
                      :hangup_cause => cdrFS.hangup_cause,
                      :uuid => cdrFS.uuid,
                      :bleg_uuid => cdrFS.bleg_uuid,
                      :account_code => cdrFS.account_code
                      )
        cdr.save()
        total_imported += 1
      end
    end
    return total_imported
  end
  
end
