class TeamsUser < ApplicationRecord
  belongs_to :user
  belongs_to :team

  def name(ip_address = nil)
    name = user.name(ip_address)
  end

  def get_team_members(team_id)
    team_members = TeamsUser.where('team_id = ?', team_id)
    user_ids = team_members.pluck(:user_id)
    users = User.where(id: user_ids)

    return users
  end

  # Removes entry in the TeamUsers table for the given user and given team id
  def self.remove_team(user_id, team_id)
    team_user = TeamsUser.where('user_id = ? and team_id = ?', user_id, team_id).first
    team_user&.destroy
  end

  def self.team_id(assignment_id, user_id)
    # team_id variable represents the team_id for this user in this assignment
    team_id = nil
    teams_users = TeamsUser.where(user_id: user_id)
    teams_users.each do |teams_user|
      if teams_user.team_id == nil
        next
      end
      team = Team.find(teams_user.team_id)
      if team.parent_id == assignment_id
        team_id = teams_user.team_id
        break
      end
    end
    team_id
  end

end
