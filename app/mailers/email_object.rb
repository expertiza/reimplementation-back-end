class EmailObject
  attr_accessor :subject, :body, :from, :to

  def initialize(to = nil, from = nil, subject = nil, body = nil)
    self.subject = subject
    self.body = body
    self.from = from
    self.to = to
  end
end
