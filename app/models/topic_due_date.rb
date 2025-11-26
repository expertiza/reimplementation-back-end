# frozen_string_literal: true

class TopicDueDate < DueDate
  def self.next_due_date(assignment_id, topic_id)
    topic_deadline = where(parent_id: topic_id, parent_type: 'SignUpTopic')
                     .where('due_at >= ?', Time.current)
                     .order(:due_at)
                     .first

    topic_deadline || DueDate.where(parent_id: assignment_id, parent_type: 'Assignment')
                             .where('due_at >= ?', Time.current)
                             .order(:due_at)
                             .first
  end
end
