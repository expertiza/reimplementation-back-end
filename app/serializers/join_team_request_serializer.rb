class JoinTeamRequestSerializer < ActiveModel::Serializer
  attributes :id, :comments, :reply_status, :created_at, :updated_at
  
  # Include participant information
  attribute :participant do
    {
      id: object.participant.id,
      user_id: object.participant.user_id,
      user_name: object.participant.user.name,
      user_email: object.participant.user.email,
      handle: object.participant.handle
    }
  end
  
  # Include team information
  attribute :team do
    {
      id: object.team.id,
      name: object.team.name,
      type: object.team.type,
      team_size: object.team.participants.count,
      max_size: object.team.is_a?(AssignmentTeam) ? object.team.assignment&.max_team_size : nil,
      is_full: object.team.full?
    }
  end
end
