# frozen_string_literal: true

class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :team_size, :parent_id, :assignment_id
  has_many :members, serializer: ParticipantSerializer
  has_many :users, serializer: UserSerializer

  # Serializes participants through the join table so team membership matches the current team roster.
  def members
    # Use teams_participants association to get participants
    object.teams_participants.includes(:participant).map(&:participant)
  end

  # Returns the current member count without loading all serialized users.
  def team_size
    object.teams_participants.count
  end

  # Exposes parent_id as assignment_id only for assignment-backed teams.
  def assignment_id
    object.parent_id if object.is_a?(AssignmentTeam)
  end

  # Returns the topic this team is currently signed up for, if any.
  def sign_up_topic
    signed_up_team&.project_topic
  end

  # Looks up the signup join row used to derive topic context for the team.
  def signed_up_team
    SignedUpTeam.find_by(team_id: object.id)
  end

end
