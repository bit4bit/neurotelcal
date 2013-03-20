# Copyright (C) 2012 Bit4Bit <bit4bit@riseup.net>
#
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


=begin
Debido al crecimiento que se esta teniendo con la informacion
y ya que no toda es necesaria mantenerla, se archivaran
los modelos *PlivoCall*,*Campaign*, *Client*,*Call*
para volver a reconstruir en caso de ser necesario.
=end
class ArchiveJob < Struct.new(:archive_id, :action)
  def perform
    case self.action
    when :restore
      restore()
    when :archive
      archive()
    end
  end

  private
  def restore
    archive = Archive.find(self.archive_id)
    Rails.logger.debug("Restoring archive campaign id %d " % archive.campaign_id)

    archive.update_column(:processing, true)
    archive.auto_parse do |e,t|
      Archive.disable_security

      case t
      when :campaign
        c = Campaign.from_xml(e)
        begin c.group.each{|g| g.save(:validate => false) if g.id?}  ;rescue; end
        begin c.resource.each{|r| r.save(:validate => false) if r.id?} ;rescue; end
        begin c.entity.each{|e| e.save(:validate => false) if e.id?} ;rescue; end
      when :call
        c = Call.from_xml(e)
      end
      Rails.logger.debug(c.inspect)
      begin
        c.save(:validate => false) if c.id?
      rescue Exception => e
        Rails.logger.error("ArchiveJob: %s" % e.message)
      end
    end
    archive.update_column(:processing, false)
    begin  File.unlink(archive.path) ;rescue; end
    archive.destroy
  end
  
  def archive
    archive = Archive.find(self.archive_id)
    if not archive.campaign
      Rails.logger.debug("Archiving not have campaign\n")
      return false
    end
    
    Rails.logger.debug("Archiving Campaign %s" % archive.campaign.name)
    messages_id = archive.campaign.group.map{|g| g.id_messages_share_clients}.flatten
    calls = Call.where(:message_id => messages_id)

    archive.update_column(:processing, true)

    count_saved = 0
    Zlib::GzipWriter.open(archive.path) do |gz|
      gz.write "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      gz.write "<archive created_at=\"%s\" campaign=\"%s\">\n" % [archive.created_at, archive.campaign.name]
      #@attention esto puede causar consumo de mucha memoria
      #ya que al parecer to_xml carga todos los registros en memoria
      #para luego pasalos a xml..(no he probado esto)
      gz.write archive.campaign.to_xml :skip_instruct => true, :include => {
        :resource => {}, 
        :plivo => {},
        :group => {:include => {:client => {}, :message => {:include => {:message_calendar => {}}}}},
        :entity => {}
      }
      
      gz.write "<call type=\"array\">\n"
      calls.each do |call|
        count_saved += 1
        gz.write call.to_xml :skip_instruct => true, :include => [:plivo_call]
      end
      gz.write "</call>\n"
      gz.write "</archive>"
    end



    #elimina todo lo archivado
    archive.campaign.group.each{|g| g.client.delete_all}
    archive.campaign.group.each{|g| g.message.each{|m| m.message_calendar.delete_all}; g.message.delete_all}
    archive.campaign.group.delete_all
    archive.campaign.resource.delete_all
    archive.campaign.destroy
    calls = Call.where(:message_id => messages_id)
    calls.each do |call|
      call.plivo_call.destroy
      call.destroy
    end
    archive.update_column(:processing, false)
  end
  
  
end
