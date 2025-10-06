class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :team_size, :assignment
  has_many :members, serializer: UserSerializer
  belongs_to :assignment, serializer: AssignmentSerializer

  def members
    # Use teams_participants association to get users
    object.teams_participants.includes(:user).map(&:user)
  end

  def team_size
    object.teams_participants.count
  end

  # def assignment
  #   # Return parent_id for AssignmentTeam, nil for CourseTeam
  #   object.is_a?(AssignmentTeam) ? object.assignment : nil
  # end
end 
