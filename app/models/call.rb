class Call < ActiveRecord::Base
  attr_accessible :client_id, :completed_p, :length, :message_id, :entered, :listened, :hangup_enumeration, :status

  belongs_to :message
  belongs_to :client

  #Retorna estado de c
  def hangup_status
    case self.hangup_enumeration
    when 'USER_BUSY'
      return 'USUARIO/A OCUPADO/A'
    when 'SUBSCRIBER_ABSENT'
      return 'USUARI/A AUSENTE'
    when 'CALL_REJECTED'
      return 'LLAMADA_RECHAZADA'
    when 'NORMAL_CLEARING'
      return 'COLGADO NORMAL'
    else
      return self.hangup_enumeration
    end
  end

end
