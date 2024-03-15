# app/controllers/api/v1/authentication_controller.rb
require 'json_web_token'

class AuthenticationController < ApplicationController
  skip_before_action :authenticate_request!

  # POST /login
  def login
    user = User.find_by(name: params[:user_name]) || User.find_by(email: params[:user_name])

    if user&.authenticate(params[:password])
      payload = {
        id: user.id,
        name: user.name,
        full_name: user.full_name,
        role: user.role&.name,  # Use safe navigation operator (&.) to avoid nil error
        institution_id: user.institution&.id  # Use safe navigation operator (&.) to avoid nil error
      }

      token = JsonWebToken.encode(payload, 24.hours.from_now)
      render json: { token: token }, status: :ok  # Include the actual token value in the response
    else
      render json: { error: 'Invalid username/password combination' }, status: :unauthorized
    end
  end

end
