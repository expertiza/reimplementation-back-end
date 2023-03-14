class ApplicationMailer < ActionMailer::Base
  default from: 'from@example.com'
  layout 'mailer'

  def sync_message(defn)
    mail(subject: defn[:subject],
         to: defn[:to])
  end

end
