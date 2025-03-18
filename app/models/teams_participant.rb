class TeamsParticipant < ApplicationRecord
  belongs_to :participant
  belongs_to :team

  delegate :name, to: :user, prefix: true, allow_nil: true

  def self.team_members(team_id)
    user_ids = where(team_id: team_id).pluck(:participant_id)
    User.where(id: user_ids)
  end

  def self.remove_participant_from_team(user_id, team_id)
    find_by(participant_id: user_id, team_id: team_id)&.destroy
  end
end