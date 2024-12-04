class TeamsUser < ApplicationRecord
  belongs_to :user
  belongs_to :team
  has_one :team_user_node, foreign_key: 'node_object_id', dependent: :destroy

  # Retrieves the team members for a specific team.
  def get_team_members(team_id)
    team_members = TeamsUser.where('team_id = ?', team_id)
    user_ids = team_members.pluck(:user_id)
    User.where(id: user_ids)
  end

  # Removes entry in the TeamUsers table for the given user and team ID.
  def self.remove_team(user_id, team_id)
    team_user = TeamsUser.find_by(user_id: user_id, team_id: team_id)
    team_user&.destroy
  end

#E2479
  # Deletes multiple team members in bulk.
  def self.bulk_delete_participants(team_user_ids)
    where(id: team_user_ids).destroy_all
  end

  # Custom name display for mentors.
  def name(ip_address = nil)
    name = user.name(ip_address)
    name += ' (Mentor)' if MentorManagement.user_a_mentor?(user)
    name
  end
end
