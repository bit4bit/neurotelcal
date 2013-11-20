class Operators::SessionsController < Devise::SessionsController

  def after_sign_in_path_for(resource)
    operators_monitor_index_url
  end

  def after_sign_out_path_for(resource)
    new_operators_user_session_url
  end
  
end
