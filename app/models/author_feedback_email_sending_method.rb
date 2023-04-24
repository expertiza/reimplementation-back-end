class AuthorFeedbackEmailSendingMethod < EmailSendingMethod
  attr_reader :command
  attr_reader :assignment
  attr_reader :reviewed_object_id
  def initialize(command, assignment, reviewed_object_id)
    @command = command
    @assignment = assignment
    @reviewed_object_id = reviewed_object_id
  end
  def accept(visitor)
      visitor.visit(self)
    end
  end