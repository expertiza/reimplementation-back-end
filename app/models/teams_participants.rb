class TeamsUser < ApplicationRecord
  belongs_to :user
  belongs_to :team

  # Returns the user's name. If an IP address is provided, it may influence the name retrieval logic.
  def name(ip_address = nil)
    user.name(ip_address)
  end

  # Retrieves all team members for a given team ID as a collection of User objects.
  # Allows optional exclusion of certain roles.
  def self.get_team_members(team_id, excluded_roles: [])
    users = where(team_id: team_id).includes(:user).map(&:user)
    return users if excluded_roles.empty?

    # Exclude users with specific roles, if any
    users.reject { |user| excluded_roles.include?(user.role) }
  end

  # Adds a user to a team. Raises an error if the user is already on the team.
  # Returns the created TeamsUser object if successful.
  def self.add_to_team(user_id, team_id)
    # Check if the user is already a team member
    if where(user_id: user_id, team_id: team_id).exists?
      raise "The user is already a member of the team."
    end

    # Create the association
    create!(user_id: user_id, team_id: team_id)
  rescue ActiveRecord::RecordInvalid => e
    raise "Failed to add user to team: #{e.message}"
  end

  # Removes a user's association with a team. Raises an error if the association does not exist.
  def self.remove_from_team(user_id, team_id)
    team_user = find_by(user_id: user_id, team_id: team_id)
    raise "The user is not a member of this team." if team_user.nil?

    team_user.destroy
  rescue StandardError => e
    raise "Failed to remove user from team: #{e.message}"
  end

  # Transfers a user from one team to another within the same context.
  # Ensures that the user is removed from the previous team before adding to the new one.
  def self.transfer_user_to_team(user_id, old_team_id, new_team_id)
    remove_from_team(user_id, old_team_id)
    add_to_team(user_id, new_team_id)
  rescue StandardError => e
    raise "Failed to transfer user between teams: #{e.message}"
  end

  # Checks if a user is already on a team.
  def self.user_on_team?(user_id, team_id)
    where(user_id: user_id, team_id: team_id).exists?
  end

  # Retrieves all teams for a given user as a collection of Team objects.
  def self.get_teams_for_user(user_id)
    team_ids = where(user_id: user_id).pluck(:team_id)
    Team.where(id: team_ids)
  end
end
