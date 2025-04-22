class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants
  belongs_to :assignment
  attr_accessor :max_participants

  # Find all teams that a user belongs to for a specific assignment
  # @param assignment_id [Integer] The ID of the assignment
  # @param user_id [Integer] The ID of the user
  # @return [Array<Team>] Array of teams the user belongs to in the assignment
  def self.find_team_for_assignment_and_user(assignment_id, user_id)
    joins(:teams_users)
      .where(assignment_id: assignment_id, teams_users: { user_id: user_id })
  end

  # TODO Team implementing Teams controller and model should implement this method better.
  # TODO partial implementation here just for the functionality needed for join_team_tequests controller
  def full?
    max_participants ||= 3
    if participants.count >= max_participants
      true
    else
      false
    end
  end

  # Returns the name of the team, which is a combination of the team ID and the names of its members
  def name
    member_names = users.map(&:name).join(', ')
    "Team #{id} (#{member_names})"
  end
end