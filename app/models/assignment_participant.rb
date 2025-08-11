class AssignmentParticipant < Participant
  belongs_to  :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'
  has_many    :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many    :response_maps, foreign_key: 'reviewee_id'
  belongs_to  :user
  validates   :handle, presence: true

  # Fetches the team for specific participant
  def team
    AssignmentTeam.team(self)
  end

  # Fetches Assignment Directory.
  def dir_path
    assignment.try :directory_path
  end

  # Gets the student directory path
  def path
    "#{assignment.path}/#{team.directory_num}"
  end

  def set_handle
    self.handle = if user.handle.nil? || (user.handle == '')
                    user.name
                  elsif Participant.exists?(assignment_id: assignment.id, handle: user.handle)
                    user.name
                  else
                    user.handle
                  end
    self.save
  end
end
