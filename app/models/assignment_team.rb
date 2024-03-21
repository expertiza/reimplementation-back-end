class AssignmentTeam < Team
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
end
