class UserMailer < ApplicationMailer
    default from: "expertizamailer@gmail.com"
  
    def password_reset(user)
      @user = user
    #   check what should be the reset url
    #   @reset_url = "https://yourfrontend.com/reset-password?token=#{user.reset_password_token}"
      mail(to: @user.email, subject: "Password Reset Instructions")
    end
  end
  