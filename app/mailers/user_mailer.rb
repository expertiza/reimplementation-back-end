class UserMailer < ApplicationMailer
  default from: "expertizamailer@gmail.com"

  def send_password_reset_email(user)
    @user = user
    @reset_url = "http://localhost:3000/password_edit/check_reset_url?token=#{@user.reset_password_token}"
    mail(to: @user.email, subject: 'Expertiza password reset')
  end
end
