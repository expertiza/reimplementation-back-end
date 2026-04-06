# frozen_string_literal: true

class MentoredTeam < AssignmentTeam

  # adds members to the team who are not mentors
  def add_member(participant)
    return false if participant == mentor
    super(participant)
  end

  # Assigning a participant as mentor of the team
  # Validates if participant has the duty of mentor
  def assign_mentor(participant)
    mentor_duty = Duty.find_by(name: 'Mentor')
    return false unless mentor_duty
    return false unless participants.exists?(id: participant.id)

    participant.update(duty_id: mentor_duty.id)
  end

  # Unassigns mentor from team
  def remove_mentor
    mentor_duty = Duty.find_by(name: 'Mentor')
    return unless mentor_duty

    # Use raw SQL join because AssignmentParticipant has no has_many :teams_participants association.
    # duty_id lives on participants table; team scoping is done via teams_participants.team_id.
    mentor_participant = AssignmentParticipant
                           .joins('INNER JOIN teams_participants ON teams_participants.participant_id = participants.id')
                           .where('teams_participants.team_id = ? AND participants.duty_id = ?', id, mentor_duty.id)
                           .first
    mentor_participant&.update(duty_id: nil)
  end

  private

  # Check if the team type is 'MentoredTeam'
  def type_must_be_mentored_team
    errors.add(:type, 'must be MentoredTeam') unless type == 'MentoredTeam'
  end

  # Returns the participant on this team who has the Mentor duty
  def mentor
    mentor_duty = Duty.find_by(name: 'Mentor')
    return nil unless mentor_duty

    # Use raw SQL join because AssignmentParticipant has no has_many :teams_participants association.
    # duty_id lives on participants table; team scoping is done via teams_participants.team_id.
    AssignmentParticipant
      .joins('INNER JOIN teams_participants ON teams_participants.participant_id = participants.id')
      .where('teams_participants.team_id = ? AND participants.duty_id = ?', id, mentor_duty.id)
      .first
  end
end
