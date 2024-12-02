class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants
  belongs_to :assignment
  attr_accessor :max_participants

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

  # Add member to the team, changed to hash by E1776
  def add_member(user, _assignment_id)
    raise "The user #{user.name} is already a member of the team #{name}" if user?(user)

    can_add_member = false
    unless full?
      can_add_member = true
      add_participant(_assignment_id, user)
    end
    can_add_member
  end

  def user?(user)
    users.include? user
  end
  
  # TODO :: Remove the team from waitlist, once Waitlist is implemented
  def remove_team_user(team_id:, user_id:)
    if TeamsUser.exists?(team_id: team_id, user_id: user_id)
      TeamsUser.where(team_id: team_id, user_id: user_id).destroy_all
    end

    # if this user is the last member of the team then the team does not
    # have any members, delete the entry for the team
    if TeamsUser.where(team_id: team_id).empty?
      old_team = AssignmentTeam.find team_id
      if (old_team && Team.size(team_id) == 0 && !old_team.received_any_peer_review?)
        old_team.destroy

        # if assignment has signup sheet then the topic selected by the team has to go back to the pool
        # or to the first team in the waitlist
        # Waitlist.remove_from_waitlists(team_id)
      end
    end
  end

end