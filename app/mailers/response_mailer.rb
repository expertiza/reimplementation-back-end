class ResponseMailer < ApplicationMailer
    default from: 'from@example.com'

    # Send an email to authors from a reviewer
    def send_response_email(response)

        @body = response.params[:send_email][:email_body]
        @subject = params[:send_email][:subject]

        Rails.env.development? || Rails.env.test? ? @email = 'expertiza.mailer@gmail.com' : @email = response.params[:email]
        mail(to: @email, body: @body, subject: @subject, content_type: 'text/html',)

    end

    #Email a professor 
    def send_score_difference_email(response)
        @response = response
        @response_map = response.map
        @reviewer = AssignmentParticipant.find(@response_map.reviewer_id)
        @reviewer_name = User.find(@reviewer.user_id).fullname
        @reviewee_team = AssignmentTeam.find(@response_map.reviewee_id)
        @reviewee_participant = @reviewee_team.participants.first
        @reviewee_name = User.find(@reviewee_participant.user_id).fullname
        @assignment = Assignment.find(@reviewer.parent_id)


        Rails.env.development? || Rails.env.test? ? @email = 'expertiza.mailer@gmail.com' : @email = response.params[:email]
        mail(to: @assignment.instructor.email,       body: {
            reviewer_name: @reviewer_name,
            type: 'review',
            reviewee_name: @reviewee_name,
            assignment: @assignment,
            conflicting_response_url: 'https://expertiza.ncsu.edu/response/view?id=' + @response.id.to_s,
            summary_url: 'https://expertiza.ncsu.edu/grades/view_team?id=' + @reviewee_participant.id.to_s,
            assignment_edit_url: 'https://expertiza.ncsu.edu/assignments/' + @assignment.id.to_s + '/edit'
          }
          subject: 'Expertiza Notification: A review score is outside the acceptable range', content_type: 'text/html',)
    end

end