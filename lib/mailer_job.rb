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

class MailerJob
  attr_accessor :to, :content, :plivocall_id
  def initialize(to, content, plivocall_id)
    @to = to
    @content = content
    @plivocall_id = plivocall_id

  end
  
  def perform
    @plivocall = PlivoCall.find(@plivocall_id)
    Rails.logger.debug('sending email to %s' % to)
    CallMailer.message_email(@to, @content, @plivocall).deliver
    
  end
  
end

