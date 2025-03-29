class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :team_participants, dependent: :destroy
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

  def participant?(participant)
    participants.exists?(id: participant.id)
  end

  def add_member(participant)
    raise "The participant #{participant.user.name} is already a member of this team" if participant?(participant)
    return false if full?

    # Create a TeamParticipant record linking the participant to this team.
    TeamParticipant.create(user_id: participant.id, team_id: id)
    # ExpertizaLogger.info LoggerMessage.new('Model:Team', participant.name, "Added participant to the team #{id}")
    true
  end

  def add_participants_with_validation(participant)
    begin
      if add_member(participant)
        { success: true }
      else
        { success: false, error: "Unable to add participant: team is at full capacity." }
      end
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end


end