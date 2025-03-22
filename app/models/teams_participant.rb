class TeamsParticipant < ApplicationRecord
  belongs_to :participant
  belongs_to :team

  delegate :name, to: :user, prefix: true, allow_nil: true

  # E2516: Fetches all participants associated with a given team.
  # @param [Integer] team_id - ID of the team
  # @return [Array] Array of user records
  def self.team_members(team_id)
    participant_ids = where(team_id: team_id).pluck(:participant_id)
    User.where(id: participant_ids)
  end

  # E2516: Removes a participant from the team.
  # @param [Integer] user_id - ID of the participant to be removed
  # @param [Integer] team_id - ID of the team
  def self.remove_participant_from_team(participant_id, team_id)
    find_by(participant_id: participant_id, team_id: team_id)&.destroy
  end
end
