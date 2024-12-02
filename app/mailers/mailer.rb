class Mailer < ActionMailer::Base
  default from: 'expertiza.mailer@gmail.com'

  def send_topic_approved_email(defn)
    @suggester = defn[:suggester]
    @topic_name = defn[:topic_name]
    mail(to: @suggester.email, cc: defn[:cc], subject: defn[:subject]).deliver_now!
  end
end
