class AssignmentDueDate < DueDate
    def self.get_next_due_date(assignment_id)
        find_by(['parent_id = ? && due_at >= ?', assignment_id, Time.zone.now])
    end
end