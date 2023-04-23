class TeammateReviewEmailSendingMethod < EmailSendingMethod
    def send_email(email_command, assignment)
      email_command[:body][:type] = 'Teammate Review'
      participant = AssignmentParticipant.find(reviewee_id)
      email_command[:body][:obj_name] = assignment.name
      user = User.find(participant.user_id)
      email_command[:body][:first_name] = user.fullname
      email_command[:to] = user.email
  
      visitor.visit(email_command)
    end
  end