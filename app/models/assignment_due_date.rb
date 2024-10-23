class AssignmentDueDate < DueDate
    def self.get_due_dates(assignment_id)
        find_by(['parent_id = ? && due_at >= ?', assignment_id, Time.zone.now])
    end
end