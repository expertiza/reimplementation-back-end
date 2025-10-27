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

  # === Abstract Methods (must be implemented by subclasses) ===

  # Returns the parent object (e.g., Course or Assignment)
  def parent_entity
    raise NotImplementedError, "#{self.class} must implement #parent_entity"
  end

  # Returns the required Participant class (e.g., CourseParticipant)
  def participant_class
    raise NotImplementedError, "#{self.class} must implement #participant_class"
  end

  # Returns a string label for the context (e.g., 'course')
  def context_label
    raise NotImplementedError, "#{self.class} must implement #context_label"
  end

  # === Core API ===

  def max_team_size
    nil # Default: no limit (overridden by AssignmentTeam)
  end

  def has_member?(user)
    participants.exists?(user_id: user.id)
  end

  def full?
    return false unless max_team_size
    # Note: MentoredTeam overrides this to exclude the mentor
    participants.count >= max_team_size
  end

  # Uses polymorphic parent_entity instead of type checking
  def participant_on_team?(participant)
    return false unless parent_entity

    TeamsParticipant
      .where(participant_id: participant.id, team_id: parent_entity.teams.select(:id))
      .exists?
  end

  # Adds a participant to the team.
  # This is a Template Method, customizable via hooks.
  def add_member(participant)
    eligibility = can_participant_join_team?(participant)
    return eligibility unless eligibility[:success]

    return { success: false, error: 'Team is at full capacity.' } if full?

    validation_result = validate_participant_type(participant)
    return validation_result unless validation_result[:success]

    # Added hook for subclass-specific validation (e.g., MentoredTeam)
    hook_result = validate_participant_for_add(participant)
    return hook_result unless hook_result[:success]

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

    { success: true }
  end

  def size
    participants.count
  end

  def empty?
    participants.empty?
  end

  protected

  # Copies members from this team to a target_team.
  def copy_members_to_team(target_team)
    target_parent = target_team.parent_entity

    participants.each do |source_participant|
      # Find or create the corresponding participant in the target context
      target_participant = target_team.participant_class.find_or_create_by!(
        user_id: source_participant.user_id,
        parent_id: target_parent.id
      ) do |p|
        p.handle = source_participant.handle
      end

      # Use the public add_member API to ensure all rules are followed
      target_team.add_member(target_participant)
    end
  end

  # This ensures a participant's context (Course) matches the team's (Course).
  def validate_participant_type(participant)
    unless participant.parent_context == parent_entity
      return {
        success: false,
        error: "Participant belongs to #{participant.parent_context.name} (a #{participant.parent_context.class}), " \
               "but this team belongs to #{parent_entity.name} (a #{parent_entity.class})."
      }
    end
    { success: true }
  end

  # Added hook for the Template Method Pattern.
  # Subclasses can override this to add custom validation to add_member.
  def validate_participant_for_add(_participant)
    { success: true } # Default: no extra validation
  end
end
