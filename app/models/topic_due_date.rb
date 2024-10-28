class TopicDueDate < DueDate
  def self.next_due_date(assignment_id, topic_id)
    next_due_dates = where('parent_id = ? and due_at >= ?', topic_id, Time.zone.now)

    # If there are no due dates for the topic, then check if there are any due dates for the assignment
    if next_due_dates.any? == false
      next_due_dates = where('parent_id = ? and due_at >= ?', assignment_id, Time.zone.now)
    end

    # Sort the due dates and return the next due date
    sort_due_dates(next_due_dates).first
  end
end