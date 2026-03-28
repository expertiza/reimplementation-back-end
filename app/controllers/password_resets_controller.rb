class PasswordResetsController < ApplicationController
  before_action :find_user_by_email, only: [:create]
  before_action :load_user_by_token, only: [:update]
  skip_before_action :authenticate_request!, only: [:create, :update]

  # POST /password_resets
  def create
    if @user
      token = @user.generate_token_for(:password_reset)
      UserMailer.password_reset_email(@user, token).deliver_later
    end

    # Always return a 200 OK to prevent email enumeration attacks
    render json: { message: I18n.t('password_reset.email_sent') }, status: :ok
  end

  # PATCH/PUT /password_resets/:token
  def update
    if @user.update(password_params)
      render json: { message: I18n.t('password_reset.updated') }, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def find_user_by_email
    @user = User.find_by(email: params[:email].to_s.strip.downcase)
  end

  def load_user_by_token
    @user = User.find_by_token_for(:password_reset, params[:token])
    render_invalid_token_response unless @user
  end

  def render_invalid_token_response
    render json: { error: I18n.t('password_reset.errors.token_expired') }, status: :unprocessable_entity
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end