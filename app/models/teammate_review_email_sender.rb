class TeammateReviewEmailSender < EmailSender
  attr_reader :command
  attr_reader :assignment
  attr_reader :reviewee_id
  def initialize(command, assignment, reviewee_id)
    @command = command
    @assignment = assignment
    @reviewee_id = reviewee_id
  end
  #Accepting the visitor for email_sender class
  def accept(visitor)
    visitor.visit(self)
  end
  end