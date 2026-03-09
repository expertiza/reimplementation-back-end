class UserMailer < ApplicationMailer
  default from: "expertizamailer@gmail.com"

  def send_password_reset_email(token)
    @reset_url = "http://localhost:3000/password_edit/check_reset_url?token=#{token}"
    mail(to: @user.email, subject: I18n.t('password_edit.subject'))
  end
end
