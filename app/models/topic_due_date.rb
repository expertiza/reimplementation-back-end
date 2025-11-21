# frozen_string_literal: true

class TopicDueDate < DueDate
  # overwrite super method with additional logic to check for topic first
  def self.next_due_date(assignment_id, topic_id)
    next_due_date = super(topic_id)

    next_due_date ||= DueDate.next_due_date(assignment_id)

    next_due_date
  end
end
