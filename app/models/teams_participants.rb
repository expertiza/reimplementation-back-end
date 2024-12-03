class TeamsParticipant < ApplicationRecord
  belongs_to :user
  belongs_to :team
  has_one :team_user_node, foreign_key: 'node_object_id', dependent: :destroy
  has_paper_trail

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

#E2479
# Retrieves the name of the user associated with the team member.
# Optionally appends ' (Mentor)' if the user is a mentor.
# Params:
# - ip_address (optional): The IP address of the user (used for logging or contextual name resolution).
# Returns:
# - The name of the user, with '(Mentor)' appended if the user is a mentor.
def display_name(ip_address = nil)
  participant_name = user.name(ip_address)
  participant_name += ' (Mentor)' if MentorManagement.user_a_mentor?(user)
  participant_name
end

# Deletes multiple team members (identified by their IDs) in bulk.
# This method is used for efficient removal of multiple TeamsUser records.
# Params:
# - team_user_ids: An array of IDs of the TeamsUser records to be deleted.
# Returns:
# - The number of records deleted (implicit return from destroy_all).
def self.bulk_delete(team_user_ids)
  # Delete all TeamsUser records matching the provided IDs.
  where(id: team_user_ids).destroy_all
end

# Checks whether a specific user is a member of a given team.
# Params:
# - user_id: The ID of the user to check.
# - team_id: The ID of the team to check for membership.
# Returns:
# - true if the user is a member of the team.
# - false otherwise.
def self.participant_part_of_team?(user_id, team_id)
  # Check if a TeamsUser record exists with the specified user and team IDs.
  exists?(user_id: user_id, team_id: team_id)
end

# Checks whether a team is empty (i.e., has no members).
# Params:
# - team_id: The ID of the team to check.
# Returns:
# - true if the team has no members.
# - false otherwise.
def self.is_team_empty?(team_id)
  # Retrieve all members of the team.
  team_members = TeamsUser.where('team_id = ?', team_id)

  # Return true if the team has no members; false otherwise.
  team_members.blank?
end


end
