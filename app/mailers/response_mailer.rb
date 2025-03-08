class ResponseMailer < ApplicationMailer
    default from: 'from@example.com'

    # Send an email to authors from a reviewer
    def send_response_email(response)

        @body = response.params[:send_email][:email_body]
        @subject = params[:send_email][:subject]

        Rails.env.development? || Rails.env.test? ? @email = 'expertiza.mailer@gmail.com' : @email = response.params[:email]
        mail(to: @email, body: @body, subject: @subject, content_type: 'text/html',)

    end
end
