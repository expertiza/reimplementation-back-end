# frozen_string_literal: true

class TopicDueDate < DueDate
  # TopicDueDate is a subclass of DueDate that uses single table inheritance
  # The 'type' field in the database will be automatically set to 'TopicDueDate'
  # when instances of this class are created.
  #
  # This class inherits all functionality from DueDate and doesn't need
  # any additional methods since the parent class and DueDateActions concern
  # already handle topic-specific due date logic properly.
end
