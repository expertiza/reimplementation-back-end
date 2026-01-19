# frozen_string_literal: true

# app/validators/invitation_validator.rb
class InvitationValidator < ActiveModel::Validator
  ACCEPT_STATUS = 'A'.freeze
  DECLINED_STATUS = 'D'.freeze
  WAITING_STATUS = 'W'.freeze
  RETRACT_STATUS = 'R'.freeze

  DUPLICATE_INVITATION_ERROR_MSG = 'You cannot have duplicate invitations'.freeze
  TO_FROM_SAME_ERROR_MSG = 'to and from participants should be different'.freeze
  REPLY_STATUS_ERROR_MSG = 'must be present and have a maximum length of 1'.freeze
  DIFFERENT_ASSIGNMENT_PARTICIPANT_MSG = "the participant is not part of this assignment".freeze
  REPLY_STATUS_INCLUSION_ERROR_MSG = "must be one of #{[ACCEPT_STATUS, DECLINED_STATUS, WAITING_STATUS, RETRACT_STATUS].to_sentence}".freeze

  def validate(record)
    validate_invitee(record)
    validate_reply_status(record)
    validate_reply_status_inclusion(record)
    validate_duplicate_invitation(record)
    validate_to_from_different(record)
  end

  private

  # validates if the invitee is participant of the assignment or not
  def validate_invitee(record)
    participant = AssignmentParticipant.find_by(id: record.to_id, parent_id: record.assignment_id)
    unless participant.present?
      record.errors.add(:base, DIFFERENT_ASSIGNMENT_PARTICIPANT_MSG)
    end
  end

  def validate_reply_status(record)
    unless record.reply_status.present? && record.reply_status.length <= 1
      record.errors.add(:base, REPLY_STATUS_ERROR_MSG)
    end
  end

  def validate_reply_status_inclusion(record)
    unless [ACCEPT_STATUS, DECLINED_STATUS, WAITING_STATUS, RETRACT_STATUS].include?(record.reply_status)
      record.errors.add(:base, REPLY_STATUS_INCLUSION_ERROR_MSG)
    end
  end

  def validate_duplicate_invitation(record)
    conditions = {
      id: record&.id,
      to_id: record.to_id,
      from_id: record.from_id,
      assignment_id: record.assignment_id,
      reply_status: record.reply_status
    }
    if Invitation.where(conditions).exists?
      record.errors.add(:base, DUPLICATE_INVITATION_ERROR_MSG)
    end
  end

  def validate_to_from_different(record)
    if record.from_id == record.to_id
      record.errors.add(:base, TO_FROM_SAME_ERROR_MSG)
    end
  end
end