
class TeammateReviewEmailVisitor < EmailSendingVisitor
    def visit(mail)
      mail.command[:body][:type] = 'Teammate Review'
      participant = AssignmentParticipant.find(mail.reviewee_id)
      mail.command[:body][:obj_name] = mail.assignment.name
      user = User.find(participant.user_id)
      mail.command[:body][:first_name] = user.fullname
      mail.command[:to] = user.email

      ApplicationMailer.sync_message(mail.command).deliver
    end
end