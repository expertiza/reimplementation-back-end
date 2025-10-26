# frozen_string_literal: true

class MentoredTeam < AssignmentTeam
  # The mentor is determined by a participant on this team having a Duty
  validate :mentor_must_be_present, on: :update, if: -> { assignment.present? }

  # === Public API for Mentors ===

  # Return the mentor User (or nil)
  def mentor
    mentor_participant&.user
  end
  alias_method :mentor_user, :mentor

  # Separate method for assigning mentors
  def assign_mentor(user)
    duty = find_mentor_duty
    return { success: false, error: 'No mentor duty found for this assignment.' } unless duty

    # Find or create the participant record for this user in this assignment
    participant = assignment.participants.find_or_create_by!(
      user_id: user.id,
      parent_id: assignment.id,
      type: 'AssignmentParticipant'
    ) do |p|
      # Set handle only on creation
      p.handle = (user.try(:handle).presence || user.name)
    end

    # Assign the mentor duty
    participant.update!(duty: duty)

    # Add the participant to this team
    unless participants.exists?(id: participant.id)
      teams_participants.create!(
        participant_id: participant.id,
        team_id: id,
        user_id: participant.user_id
      )
    end

    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.debug "MentoredTeam#assign_mentor failed: #{e.record.errors.full_messages.join(', ')}"
    { success: false, error: e.record.errors.full_messages.join(', ') }
  end

  # Unassigns mentor from team
  def remove_mentor
    mp = mentor_participant
    return { success: false, error: 'No mentor found on this team.' } unless mp

    if mp.update(duty: nil)
      { success: true }
    else
      { success: false, error: mp.errors.full_messages.join(', ') }
    end
  end

  # === Overridden Methods ===

  # REFACTOR: Deleted the `add_member` override.
  # We now use the `validate_participant_for_add` hook from the base class.
  # This fixes the LSP violation.

  # Override to account for mentor not counting toward team size limit
  def full?
    return false unless max_team_size

    # Don't count the mentor toward the team size limit
    non_mentor_count = participants.count - (mentor_participant ? 1 : 0)
    non_mentor_count >= max_team_size
  end

  protected

  # This is the new hook method that `Team#add_member` calls.
  # It allows MentoredTeam to add specific validation without breaking LSP.
  def validate_participant_for_add(participant)
    if participant_is_mentor?(participant)
      return { success: false, error: "Mentors cannot be added as regular members. Use 'assign_mentor' instead." }
    end
    { success: true }
  end

  private

  def participant_is_mentor?(participant)
    participant.duty&.name&.downcase&.include?('mentor')
  end

  def find_mentor_duty
    return nil unless assignment&.persisted?
    assignment.duties.detect { |d| d.name.to_s.downcase.include?('mentor') }
  end

  def mentor_participant
    # Use find on the association to avoid loading all participants if possible
    participants.find { |p| participant_is_mentor?(p) }
  end

  def mentor_must_be_present
    # Only validate if the assignment (and thus duties) exist
    return unless assignment&.duties&.any? { |d| d.name.to_s.downcase.include?('mentor') }

    errors.add(:base, 'a mentor must be present') unless mentor_participant.present?
  end
end
