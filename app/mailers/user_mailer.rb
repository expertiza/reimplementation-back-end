class UserMailer < ApplicationMailer
  default from: "expertizamailer@gmail.com"

  def send_password_reset_email(user, token)
    frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    @user = user
    @reset_url = "#{frontend_url}/password_edit/check_reset_url?token=#{token}"
    mail(to: @user.email, subject: 'Expertiza password reset')
  end
end