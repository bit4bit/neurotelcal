class WhitelistPlivoConstraint
  def initialize
  end
  

  def matches?(request)
    if request.remote_ip == '127.0.0.1' or request.remote_ip == '0.0.0.0' or request.local?
      Rails.logger.debug("Direct access to 127.0.0.1")
      return true
    end
    
    #Permisos de servidor plivo
    if not Plivo.where('api_url LIKE ?', '%'+request.remote_ip+'%').empty?
      Rails.logger.debug("Direct access to "+request.remote_ip)
      return true
    end

    return false
  end
  
end
