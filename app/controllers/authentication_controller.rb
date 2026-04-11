class AuthenticationController < ApplicationController
  skip_before_action :authenticate_request!

  # POST /login
  def login
    user = User.find_by(name: params[:user_name]) || User.find_by(email: params[:user_name])
    if user&.authenticate(params[:password])
      token = user.generate_jwt
      render json: { token: }, status: :ok
    else
      render json: { error: 'Invalid username / password' }, status: :unauthorized
    end
  end
end
