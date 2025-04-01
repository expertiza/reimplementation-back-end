class TeamParticipant < ApplicationRecord
  belongs_to :participant
  belongs_to :team

  # Returns the name of the associated user
  def name
    participant.user.name
  end

  # Fetches team members given a team_id
  def self.get_team_members(team_id)
    team_participants = includes(participant: :user).where(team_id: team_id)
    team_participants.map(&:participant).map(&:user)
  end


  # Removes a participant from a team
  def self.remove_team(participant_id, team_id)
    team_participant = where(participant_id: participant_id, team_id: team_id).first
    team_participant&.destroy
  end
end
