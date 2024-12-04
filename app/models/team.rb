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

  def self.size(team_id)
    #TeamsUser.where(team_id: team_id).count
    count = 0
    members = TeamsUser.where(team_id: team_id)
    members.each do |member|
      member_name = member.name
      unless member_name.include?(' (Mentor)') 
        count = count + 1
      end
    end
    count
  end

  # Add member to the team, changed to hash by E1776
  def add_member(user, _assignment_id)
    raise "The user #{user.name} is already a member of the team #{name}" if user?(user)

    can_add_member = false
    unless full?
      can_add_member = true
      t_user = TeamsUser.create(user_id: user.id, team_id: self.id)
      add_participant(_assignment_id, user)
    end
    can_add_member
  end

  def user?(user)
    users.include? user
  end
  
  # TODO :: Remove the team from waitlist, once Waitlist is implemented
  def remove_team_user(user_id:)
    if TeamsUser.exists?(team_id: self.id, user_id: user_id)
      TeamsUser.where(team_id: self.id, user_id: user_id).destroy_all
    else
      return [false, "Student does not belong to team #{self.id}"]
    end

    # if this user is the last member of the team then the team does not
    # have any members, delete the entry for the team
    # puts TeamsUser.where(team_id: self.id).inspect
    if TeamsUser.where(team_id: self.id).empty?
      old_team = AssignmentTeam.find self.id
      if (old_team && Team.size(old_team.id) == 0 && !old_team.received_any_peer_review?)
        old_team.destroy
        return [true, "Team #{self.id} is destroyed as the last user is removed"]
        # if assignment has signup sheet then the topic selected by the team has to go back to the pool
        # or to the first team in the waitlist
        # Waitlist.remove_from_waitlists(team_id)
      end
    end
    return [true, "Participant Removed Successfully"]
  end

end