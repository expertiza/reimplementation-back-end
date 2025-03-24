class Api::V1::PasswordsController < ApplicationController
    before_action :find_user_by_email, only: [:create]
    before_action :find_user_by_token, only: [:update]
  
    # User requests a password reset
    def create
      if @user
        @user.generate_password_reset_token!
        UserMailer.password_reset(@user).deliver_later
      end
      render json: { message: "If the email exists, a reset link has been sent." }, status: :ok
    end
  
    # Update password
    def update
      if @user.update(password_params)
        @user.clear_password_reset_token!
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
      @user = User.find_by(reset_password_token: params[:token])
      return render json: { error: "Invalid or expired token." }, status: :unprocessable_entity unless @user&.password_reset_valid?
    end
  
    def password_params
      params.require(:user).permit(:password, :password_confirmation)
    end
  end
  