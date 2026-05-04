# frozen_string_literal: true

class TopicDueDate < DueDate
  # overwrite super method with additional logic to check for topic first
  def self.next_due_date(assignment_id, topic_id, reference_time: Time.current)
    topic = ProjectTopic.find_by(id: topic_id)
    assignment = Assignment.find_by(id: assignment_id)

    next_due_date = topic ? super(topic, reference_time: reference_time) : nil

    next_due_date ||= DueDate.next_due_date(assignment, reference_time: reference_time)

    next_due_date
  end
end
