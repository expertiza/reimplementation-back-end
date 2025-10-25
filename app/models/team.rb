# frozen_string_literal: true

class Team < ApplicationRecord
  # Core associations
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy  
  has_many :teams_participants, dependent: :destroy
  has_many :users, through: :teams_participants
  has_many :participants, through: :teams_participants
  belongs_to :user, optional: true # Team creator
  
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { 
    in: %w[AssignmentTeam CourseTeam MentoredTeam], 
    message: "must be 'AssignmentTeam', 'CourseTeam', or 'MentoredTeam'" 
  }

  attr_accessor :max_participants
  
  # Abstract methods - must be implemented by subclasses
  def parent_entity
    raise NotImplementedError, "#{self.class} must implement #parent_entity"
  end

  def participant_class
    raise NotImplementedError, "#{self.class} must implement #participant_class"
  end

  def context_label
    raise NotImplementedError, "#{self.class} must implement #context_label"
  end

  # Template method - uses polymorphic behavior from subclasses
  def max_team_size
    nil # Default for teams without size limits (overridden in AssignmentTeam)
  end

  def has_member?(user)
    participants.exists?(user_id: user.id)
  end
  
  def full?
    return false unless max_team_size
    participants.count >= max_team_size
  end

  # Uses polymorphic parent_entity instead of type checking
  def participant_on_team?(participant)
    return false unless parent_entity
    
    TeamsParticipant
    .where(participant_id: participant.id, team_id: parent_entity.teams.select(:id))
    .exists?
  end

  # Adds a participant to the team
  def add_member(participant)
    eligibility = can_participant_join_team?(participant)
    return eligibility unless eligibility[:success]

    return { success: false, error: "Team is at full capacity." } if full?
    return { success: false, error: "Participant is already on a team for this context." } if participant_on_team?(participant)

    validation_result = validate_participant_type(participant)
    return validation_result unless validation_result[:success]

    teams_participants.create!(participant: participant, user: participant.user)
    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.record.errors.full_messages.join(', ') }
  end

  # Uses polymorphic methods instead of type checks
  def can_participant_join_team?(participant)
    if participant_on_team?(participant)
      return { success: false, error: "This user is already assigned to a team for this #{context_label}" }
    end

    registered = participant_class.find_by(
      user_id: participant.user_id,
      parent_id: parent_entity.id
    )

    unless registered
      return { success: false, error: "#{participant.user.name} is not a participant in this #{context_label}" }
    end

    { success: true }
  end

  def size
    participants.count
  end

  def empty?
    participants.empty?
  end

  protected

  # Hook for subclasses to validate participant types
  def validate_participant_type(participant)
    unless participant.is_a?(participant_class)
      return { 
        success: false, 
        error: "Cannot add #{participant.class.name} to #{self.class.name}. Expected #{participant_class.name}." 
      }
    end
    { success: true }
  end

  def validate_membership(user)
    # Default implementation - override in subclasses if needed
    true
  end
end
