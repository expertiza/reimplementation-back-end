class AuthorFeedbackEmailSendingMethod < EmailSendingMethod
    def send_email(email_command, assignment)
      email_command[:body][:type] = 'Author Feedback'
      response_id_for_original_feedback = reviewed_object_id
      response_for_original_feedback = Response.find response_id_for_original_feedback
      response_map_for_original_feedback = ResponseMap.find response_for_original_feedback.map_id
      original_reviewer_participant_id = response_map_for_original_feedback.reviewer_id
  
      participant = AssignmentParticipant.find(original_reviewer_participant_id)
  
      email_command[:body][:obj_name] = assignment.name
  
      user = User.find(participant.user_id)
  
      email_command[:to] = user.email
      email_command[:body][:first_name] = user.fullname
  
      visitor.visit(email_command)
    end
  end