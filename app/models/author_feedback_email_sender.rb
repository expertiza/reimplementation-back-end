class AuthorFeedbackEmailSender < EmailSender
  attr_reader :command
  attr_reader :assignment
  attr_reader :reviewed_object_id
  def initialize(command, assignment, reviewed_object_id)
    @command = command
    @assignment = assignment
    @reviewed_object_id = reviewed_object_id
  end
  #Accepting the visitor for email_sender class
  def accept(visitor)
      visitor.visit(self)
    end
  end