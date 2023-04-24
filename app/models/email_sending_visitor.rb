class EmailSendingVisitor
    def visit(email_command)
      raise NotImplementedError, 'This method should be implemented by the subclass'
    end
  end