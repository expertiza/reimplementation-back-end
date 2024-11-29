class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants
  belongs_to :assignment
  attr_accessor :max_participants

  # Check if the team is full
  def full?
    max_participants ||= 3 # Default maximum participants
    participants.count >= max_participants
  end

  # Add a user to the team
  def add_member(user)
    return false if full?

    TeamsUser.create!(team_id: id, user_id: user.id)
  rescue ActiveRecord::RecordInvalid => e
    raise "Failed to add member to the team: #{e.message}"
  end

  # Remove a user from the team
  def remove_member(user)
    team_user = teams_users.find_by(user_id: user.id)
    if team_user
      team_user.destroy
    else
      raise "The user #{user.name} is not a member of the team."
    end
  rescue StandardError => e
    raise "Failed to remove member from the team: #{e.message}"
  end

  # Check if a user belongs to this team
  def has_member?(user)
    users.exists?(id: user.id)
  end

  # Get all team members
  def get_members
    users
  end

  # Assign a leader to the team
  def assign_leader(user)
    team_user = teams_users.find_by(user_id: user.id)
    if team_user
      team_user.update!(role: 'leader')
    else
      raise "The user #{user.name} is not a member of the team."
    end
  rescue StandardError => e
    raise "Failed to assign team leader: #{e.message}"
  end

  # Get the team leader
  def team_leader
    teams_users.find_by(role: 'leader')&.user
  end

  # Check if the team is empty
  def empty?
    users.empty?
  end

  # Transfer all members to another team
  def transfer_members_to(other_team)
    raise "Cannot transfer members to a full team." if other_team.full?

    users.each do |user|
      other_team.add_member(user)
      remove_member(user)
    end
  rescue StandardError => e
    raise "Failed to transfer members: #{e.message}"
  end

  # Auto-assign users to the team
  def auto_assign_users(users_to_add)
    users_to_add.each do |user|
      break if full?

      add_member(user)
    end
  rescue StandardError => e
    raise "Failed to auto-assign users: #{e.message}"
  end
end