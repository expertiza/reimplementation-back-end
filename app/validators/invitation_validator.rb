# app/validators/invitation_validator.rb
class InvitationValidator < ActiveModel::Validator
  ACCEPT_STATUS = 'A'.freeze
  REJECT_STATUS = 'R'.freeze
  WAITING_STATUS = 'W'.freeze

  DUPLICATE_INVITATION_ERROR_MSG = 'You cannot have duplicate invitations'.freeze
  TO_FROM_SAME_ERROR_MSG = 'to and from participants should be different'.freeze
  REPLY_STATUS_ERROR_MSG = 'must be present and have a maximum length of 1'.freeze
  REPLY_STATUS_INCLUSION_ERROR_MSG = "must be one of #{[ACCEPT_STATUS, REJECT_STATUS, WAITING_STATUS].to_sentence}".freeze

  def validate(record)
    validate_reply_status(record)
    validate_reply_status_inclusion(record)
    validate_duplicate_invitation(record)
    validate_to_from_different(record)
  end

  private

  def validate_reply_status(record)
    unless record.reply_status.present? && record.reply_status.length <= 1
      record.errors.add(:base, REPLY_STATUS_ERROR_MSG)
    end
  end

  def validate_reply_status_inclusion(record)
    unless [ACCEPT_STATUS, REJECT_STATUS, WAITING_STATUS].include?(record.reply_status)
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