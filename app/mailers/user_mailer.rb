class UserMailer < ApplicationMailer
  default from: "expertizamailer@gmail.com"

  def send_password_reset_email(user, token)
    @user = user
    @reset_url = get_password_reset_url(token)
    mail(to: @user.email, subject: I18n.t('password_reset.email_subject'))
  end

  private

  def get_password_reset_url(token)
    frontend_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
    "#{frontend_url}/password_edit/check_reset_url?token=#{token}"
  end
end