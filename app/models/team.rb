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

  def add_member(user, _assignment_id = nil)
    raise "The user #{user.name} is already a member of the team #{name}" if user?(user)

    can_add_member = false
    unless full?
      can_add_member = true
      t_user = TeamsUser.create(user_id: user.id, team_id: id)
      parent = TeamNode.find_by(node_object_id: id)
      TeamUserNode.create(parent_id: parent.id, node_object_id: t_user.id)
      add_participant(parent_id, user)
      ExpertizaLogger.info LoggerMessage.new('Model:Team', user.name, "Added member to the team #{id}")
    end
    can_add_member
  end


  def add_participants_with_validation(user, parent_id)
    begin
      # Attempt to add the user to the team.
      add_member(user, parent_id)
      { success: true }
      # addition_result
    rescue StandardError => e
      # Return a failure message if an error occurs (e.g., user already in the team).
      { success: false, error: "The user #{user.name} is already a member of the team #{name}" }
    end
  end






end