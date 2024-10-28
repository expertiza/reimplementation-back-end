class AssignmentDueDate < DueDate
  def self.next_due_date(assignment_id)
    due_dates = AssignmentDueDate.where("parent_id = ? and due_at > ?", assignment_id, Time.zone.now)
    sorted_dates = DueDate.sort_due_dates(due_dates)
    sorted_dates.first
  end
end