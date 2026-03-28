# frozen_string_literal: true

class MentoredTeam < AssignmentTeam

  # adds members to the team who are not mentors
  def add_member(user)
    return false if user == mentor
    super(user)
  end

  # Assigning a participant as mentor of the team
  # Validates if participant has the duty of mentor
  def assign_mentor(user)
    mentor_duty = Duty.find_by(name: 'Mentor')
    return false unless mentor_duty

    participant = AssignmentParticipant.find_by(user_id: user.id, parent_id: parent_id)
    return false unless participant

    participant.update(duty_id: mentor_duty.id)
  end

  # Unassigns mentor from team
  def remove_mentor
    mentor_duty = Duty.find_by(name: 'Mentor')
    return unless mentor_duty

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

  def mentor
    mentor_duty = Duty.find_by(name: 'Mentor')
    return nil unless mentor_duty

    AssignmentParticipant
      .joins('INNER JOIN teams_participants ON teams_participants.participant_id = participants.id')
      .where('teams_participants.team_id = ? AND participants.duty_id = ?', id, mentor_duty.id)
      .first&.user
  end
end
