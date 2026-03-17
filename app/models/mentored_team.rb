# frozen_string_literal: true

class MentoredTeam < AssignmentTeam

  # Returns the participant on this team whose duty name is 'Mentor'
  def mentor
    participants.joins(:duty).find_by(duties: { name: 'Mentor' })
  end

  # Assigns a participant as mentor by setting their duty to the 'Mentor' duty.
  # The participant must already be a member of this team.
  def assign_mentor(participant)
    mentor_duty = Duty.find_by(name: 'Mentor')
    return false unless mentor_duty
    return false unless participants.exists?(id: participant.id)

    participant.update(duty_id: mentor_duty.id)
  end

  # Clears the mentor duty from the current mentor participant.
  def remove_mentor
    mentor&.update(duty_id: nil)
  end

  # Prevents adding a participant who already holds the mentor duty on this team.
  def add_member(participant_or_user)
    participant = resolve_participant(participant_or_user)
    return { success: false, error: 'Participant is already the mentor of this team' } if mentor_participant?(participant)

    super(participant_or_user)
  end

  private

  def resolve_participant(participant_or_user)
    return participant_or_user if participant_or_user.is_a?(Participant)

    AssignmentParticipant.find_by(user_id: participant_or_user.id, parent_id: parent_id)
  end

  def mentor_participant?(participant)
    return false unless participant
    mentor&.id == participant.id
  end
end
