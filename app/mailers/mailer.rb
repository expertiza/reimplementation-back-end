class Mailer < ApplicationMailer
  if Rails.env.development? || Rails.env.test?
    default from: 'expertiza.mailer@gmail.com'
  else
    default from: 'expertiza.mailer@gmail.com'
  end
  
  def send_email(email)
    email.from = from
    mail(to: email.to, subject: email.subject, from: email.from, body: email.body)
  end
end