class AuthorFeedbackEmailVisitor < EmailSendingVisitor
    def visit(email_command)
      ApplicationMailer.sync_message(email_command).deliver
    end
  end