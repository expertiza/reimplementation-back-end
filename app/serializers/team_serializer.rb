# frozen_string_literal: true

class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :max_team_size, :type, :team_size, :assignment_id
  has_many :users, serializer: UserSerializer

  def users
    object.teams_participants.includes(:user).map(&:user)
  end

  def team_size
    object.teams_participants.count
  end

  def max_team_size
    # Only AssignmentTeams have a max size, from the assignment
    object.is_a?(AssignmentTeam) ? object.assignment&.max_team_size : nil
  end

  def assignment_id
    object.is_a?(AssignmentTeam) ? object.parent_id : nil
  end
end
