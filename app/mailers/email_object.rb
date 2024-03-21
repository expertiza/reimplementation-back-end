class EmailObject
  attr_accessor :subject, :body, :from, :to

  def initialize(to = nil, from = nil, subject = nil, body = nil)
    @subject = subject
    @body = body
    @from = from
    @to = to
  end
end
