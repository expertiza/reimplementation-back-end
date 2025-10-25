# frozen_string_literal: true

class MentoredTeam < AssignmentTeam
  # The mentor is determined by a participant on this team having a Duty whose
  # name includes 'mentor' (case-insensitive).

  # validate :type_must_be_mentored_team
  validate :mentor_must_be_present, on: :update

  # Return the mentor User (or nil)
  def mentor
    mentor_participant&.user
  end
  alias_method :mentor_user, :mentor

  # Override add_member to prevent mentors from being added as regular members
  # This approach is better than rejecting in the method - we separate concerns
  def add_non_mentor_member(participant)
    if participant_is_mentor?(participant)
      return { success: false, error: 'Mentors cannot be added as regular members.' }
    end

    super(participant)
  end

  # Public interface for adding members - delegates to appropriate method
  def add_member(participant)
    # Check if this is a mentor being added
    if participant_is_mentor?(participant)
      return { success: false, error: 'Use assign_mentor to add mentors to the team.' }
    end

    add_non_mentor_member(participant)
  end

  # Separate method for assigning mentors
  def assign_mentor(user)
    duty = find_mentor_duty
    return { success: false, error: 'No mentor duty found for this assignment.' } unless duty

    participant = assignment.participants.find_or_initialize_by(
      user_id: user.id,
      parent_id: assignment.id,
      type: 'AssignmentParticipant'
    )

    participant.handle ||= (user.try(:handle).presence || user.name)
    participant.user_id ||= user.id
    participant.parent_id ||= assignment.id
    participant.type ||= 'AssignmentParticipant'

    participant.save!

    unless participant.duty == duty
      participant.duty = duty
      participant.save!
    end

    unless participants.exists?(id: participant.id)
      TeamsParticipant.create!(
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

  # Override to account for mentor not counting toward team size limit
  def full?
    return false unless max_team_size
    
    # Don't count the mentor toward the team size limit
    non_mentor_count = participants.count - (mentor_participant ? 1 : 0)
    non_mentor_count >= max_team_size
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
    participants.find { |p| participant_is_mentor?(p) }
  end

  # def type_must_be_mentored_team
  #   errors.add(:type, 'must be MentoredTeam') unless type == 'MentoredTeam'
  # end

  def mentor_must_be_present
    unless mentor_participant.present?
      errors.add(:base, 'a mentor must be present')
    end
  end
end
