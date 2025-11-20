# frozen_string_literal: true

class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :team_size, :assignment_id
  has_many :users, serializer: UserSerializer

  def users
    # Use teams_participants association to get users
    object.teams_participants.includes(:user).map(&:user)
  end

  def team_size
    object.teams_participants.count
  end

  def assignment_id
    # Return parent_id for AssignmentTeam, nil for CourseTeam
    object.is_a?(AssignmentTeam) ? object.parent_id : nil
  end
end 
