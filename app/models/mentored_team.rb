# frozen_string_literal: true

class MentoredTeam < AssignmentTeam
  # The mentor is determined by a participant on this team having a Duty whose
  # name includes 'mentor' (case-insensitive).

  validate :type_must_be_mentored_team
  validate :mentor_must_be_present

  # Return the mentor User (or nil)
  def mentor
    mentor_participant&.user
  end
  alias_method :mentor_user, :mentor

  # Adds members to the team who are not mentors
  def add_member(user)
    participant = assignment.participants.find_by(user_id: user.id)
    return false if participant&.duty&.name&.downcase&.include?('mentor')

    res = super(user)
    if res.is_a?(Hash)
      res[:success]
    else
      !!res
    end
  end

  # Assigning a user as mentor of the team
  def assign_mentor(user)
    duty = find_mentor_duty
    return false unless duty

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

    if participant.duty != duty
      participant.duty = duty
      participant.save!
    end

    unless participants.exists?(id: participant.id)
      TeamsParticipant.create!(participant_id: participant.id, team_id: id, user_id: participant.user_id)
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.debug "MentoredTeam#assign_mentor failed: #{e.record.errors.full_messages.join(', ')}"
    false
  end

  # Unassigns mentor from team: removes the duty from the participant(s)
  def remove_mentor
    mp = mentor_participant
    return false unless mp
    mp.update(duty: nil)
  end

  private

  def find_mentor_duty
    return nil unless assignment&.persisted?
    assignment.duties.detect { |d| d.name.to_s.downcase.include?('mentor') }
  end

  def mentor_participant
    participants.find { |p| p.duty&.name&.downcase&.include?('mentor') }
  end

  def type_must_be_mentored_team
    errors.add(:type, 'must be MentoredTeam') unless type == 'MentoredTeam'
  end

  def mentor_must_be_present
    unless mentor_participant.present?
      errors.add(:base, 'a mentor must be present')
    end
  end
end
