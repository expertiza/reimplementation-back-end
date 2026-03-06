class PasswordsController < ApplicationController
  before_action :find_user_by_email, only: [:create]
  before_action :find_user_by_token, only: [:update]
  skip_before_action :authenticate_request!, only: [:create, :update]

  # POST /password_resets
  def create
    if @user
      token = @user.generate_token_for(:password_reset)
      UserMailer.send_password_reset_email(token).deliver_later
    end

    # Always return a 200 OK to prevent email enumeration attacks
    render json: { message: "If the email exists, a reset link has been sent." }, status: :ok
  end

  # PATCH/PUT /password_resets/:token
  def update
    if @user.update(password_params)
      render json: { message: "Password successfully updated." }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_user_by_email
    @user = User.find_by(email: params[:email])
  end

  def find_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])

    unless @user
      render json: { error: "The token has expired or is invalid." }, status: :unprocessable_entity
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end