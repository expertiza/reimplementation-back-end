# frozen_string_literal: true

class TeamSerializer < ActiveModel::Serializer
  attributes :id, :name, :type, :team_size
  has_many :members, serializer: ParticipantSerializer

  def members
    # Use teams_participants association to get participants
    object.teams_participants.includes(:participant).map(&:participant)
  end

  def team_size
    object.teams_participants.count
  end

  def sign_up_topic
    signed_up_team&.sign_up_topic
  end

  def signed_up_team
    SignedUpTeam.find_by(team_id: object.id)
  end

end
