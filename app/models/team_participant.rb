class TeamParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :team

  # Returns the name of the associated user
  def name(_ip_address = nil)
    user.name
  end

  # Fetches team members given a team_id
  def self.get_team_members(team_id)
    team_members = where(team_id: team_id)
    user_ids = team_members.pluck(:user_id)
    User.where(id: user_ids)
  end

  # Removes a participant from a team
  def self.remove_team(user_id, team_id)
    team_participant = where(user_id: user_id, team_id: team_id).first
    team_participant&.destroy
  end
end
