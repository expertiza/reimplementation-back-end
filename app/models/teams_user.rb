class TeamsUser < ApplicationRecord
  belongs_to :user
  belongs_to :team

  def name(ip_address = nil)
    name = user.name(ip_address)
  end

  def get_team_members(team_id); end

  # Removes entry in the TeamUsers table for the given user and given team id
  def self.remove_team(user_id, team_id)
    team_user = TeamsUser.where('user_id = ? and team_id = ?', user_id, team_id).first
    team_user&.destroy
  end

  # Returns the first entry in the TeamUsers table for a given team id
  def self.first_by_team_id(team_id)
    TeamsUser.where('team_id = ?', team_id).first
  end

  # Determines whether a team is empty of not
  def self.team_empty?(team_id)
    team_members = TeamsUser.where('team_id = ?', team_id)
    team_members.blank?
  end

end