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
require 'fileutils'


#Herramientas, o acciones utiles de neurotelcal:
# * Importacion de CDRs desde sqlite del servider
# * Importacion de CSV enviado
class ToolsController < ApplicationController

  def index

  end

  #Get
  def index_archive
    @archives = Archive.paginate(:page => params[:page], :order => "created_at DESC")
    respond_to do |format|
      format.html
    end
  end
  
  #Get
  def new_archive
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }
    @archive = Archive.new
    respond_to do |format|
      format.html
    end
  end
  
  #Post
  def create_archive
    @campaigns = Campaign.all.map {|u| [u.name, u.id] }
    @archive = Archive.new(params["archive"])
    @archive.name = Campaign.find(@archive.campaign_id).name
    respond_to do |format|
      if @archive.save
        if not @archive.processing
          Delayed::Job.enqueue ::ArchiveJob.new(@archive.id, :archive), :queue => 'archive'
          format.html { redirect_to index_archive_tools_path, :notice => "Archivado correctamente."}
          format.json { render :json => @archive, :status => :created, :location => index_archive_tools_path}
        else
          format.html { redirect_to index_archive_tools_path, :error => "Actualmente esta en proceso."}
          format.json { render :json => @archive, :status => :created, :location => index_archive_tools_path}
        end
      else
        format.html { render :action => "new_archive" }
        format.json { render :json => @archive.errors, :status => :unprocessable_entity}
      end
    end
  end
  
  #GET
  def restore_archive
    @archive = Archive.find(params[:tool_id])

    respond_to do |format|
      if not @archive.processing?
        Delayed::Job.enqueue ::ArchiveJob.new(@archive.id, :restore), :queue => 'archive'
        @archive.update_column(:processing, true)
        format.html { redirect_to index_archive_tools_path, :notice => "Se ha iniciado restauracion."}
        format.json { head :no_content }
      else
        format.html { redirect_to index_archive_tools_path, :error => "Actualmente esta en proceso."}
        format.json { head :no_content }
      end
      
    end
    
  end
  
  #DELETE
  def destroy_archive
    @archive = Archive.find(params[:tool_id])

    if File.exists?(@archive.path)
      File.unlink(@archive.path).delay
    end
    @archive.destroy
    respond_to do |format|
      format.html { redirect_to index_archive_tools_path, :notice => "Eliminado correctamente."}
      format.json { head :no_content }
    end
    
  end
  
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
      CdrSqlite.establish_connection(:adapter => 'sqlite3', :database => params[:path_cdr])
      flash[:notice] = 'Find ' + CdrSqlite.all.count.to_s + ' registers on sqlite3 db. Sending to queue.'
      Delayed::Job.enqueue ::CDRJob.new(params[:path_cdr], session[:user_id]), :queue => 'cdr_import'
    end
    
    if not params[:upload_cdr].nil?
      lock = File.basename(params[:path_cdr])
      if lock_import_cdr?(lock)
        return respond_to do |format|
          format.html { render :action => 'new_import_cdr', :notice => 'Ya se esta importando este archivo' }
        end
      end

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
  def lock_import_cdr?(id)
    return File.exists?(Rails.root.join('tmp', 'lock_cdr_%s' % id))
  end

  def lock_import_cdr(id)
    File.open(Rails.root.join('tmp', 'lock_cdr_%s' % id), 'w'){|f| f.write({}.to_yaml)}
  end

  def unlock_import_cdr(id)
    File.unlink(Rails.root.join('tmp', 'lock_cdr_%s' % id))
  end

  def import_to_cdr(cdrs, lock = nil)
    total_imported = 0
    lock_import_cdr(lock)

    Notifaction.save({:user_id => session[:user_id],
                       :msg => 'Importando CDR con un total de %d registros.' % cdrs.count,
                       :type => 'notice'})
    Cdr.transaction do
      cdrs.each do |cdrFS|
        next if Cdr.where(:uuid => cdrFS.uuid).exists?
        next unless PlivoCall.where(:uuid => cdrFS.uuid).exists?
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
        data_import_cdr(lock, "count", total_imported)
        total_imported += 1
      end
    end
    unlock_import_cdr(lock)
    Notifaction.save({:user_id => session[:user_id],
                       :msg => 'Importado CDR con un total de %d registros.' % total_imported,
                       :type => 'notice'})
    return total_imported
  end
  
end
