class ApplicationController < ActionController::Base
  #include JwtToken
  def current_user
    @current_user ||= session[:user]
  end

  def current_role_name
    current_role.try :name
  end

  def current_role
    current_user.try :role
  end
end
