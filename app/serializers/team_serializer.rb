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

end