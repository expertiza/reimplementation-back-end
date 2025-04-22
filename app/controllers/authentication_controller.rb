# app/controllers/api/v1/authentication_controller.rb
require 'json_web_token'

class AuthenticationController < ApplicationController
  skip_before_action :authenticate_request!

  # POST /login
  def login
    # Add a small random delay to prevent timing attacks
    sleep(rand(0.1..0.3))
    
    user = User.find_by(name: params[:user_name]) || User.find_by(email: params[:user_name])
    
    if user&.authenticate(params[:password])
      payload = { 
        id: user.id, 
        name: user.name, 
        full_name: user.full_name, 
        role: user.role.name,
        institution_id: user.institution.id 
      }
      token = JsonWebToken.encode(payload, 24.hours.from_now)
      render json: { token: }, status: :ok
    else
      render json: { error: 'Invalid username / password' }, status: :unauthorized
    end
  end
end
