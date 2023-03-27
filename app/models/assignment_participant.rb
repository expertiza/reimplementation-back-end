class AssignmentParticipant < Participant
    belongs_to  :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
    belongs_to :user
    def handle
    end
end
