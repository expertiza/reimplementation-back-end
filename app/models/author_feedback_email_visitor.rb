class AuthorFeedbackEmailVisitor < EmailSendingVisitor
    def visit(mail)
      mail.command[:body][:type] = 'Author Feedback'
      response_id_for_original_feedback = mail.reviewed_object_id
      response_for_original_feedback = Response.find response_id_for_original_feedback
      response_map_for_original_feedback = ResponseMap.find response_for_original_feedback.map_id
      original_reviewer_participant_id = response_map_for_original_feedback.reviewer_id

      participant = AssignmentParticipant.find(original_reviewer_participant_id)

      mail.command[:body][:obj_name] = mail.assignment.name

      user = User.find(participant.user_id)

      mail.command[:to] = user.email
      mail.command[:body][:first_name] = user.fullname

      ApplicationMailer.sync_message(mail.command).deliver
    end
  end