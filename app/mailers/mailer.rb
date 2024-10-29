class Mailer < ActionMailer::Base
  default from: 'expertiza.mailer@gmail.com'

  def send_topic_approved_message(defn)
    @body = defn[:body]
    @topic_name = defn[:body][:approved_topic_name]
    @proposer = defn[:body][:proposer]

    defn[:to] = 'expertiza.mailer@gmail.com' if Rails.env.development? || Rails.env.test?
    mail(subject: defn[:subject], to: defn[:to], bcc: defn[:cc]).deliver_now!
  end
end
