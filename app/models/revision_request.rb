# frozen_string_literal: true

class RevisionRequest < ApplicationRecord
  PENDING = 'PENDING'
  APPROVED = 'APPROVED'
  DECLINED = 'DECLINED'
  STATUSES = [PENDING, APPROVED, DECLINED].freeze

  belongs_to :participant, class_name: 'AssignmentParticipant'
  belongs_to :team, class_name: 'AssignmentTeam'
  belongs_to :assignment

  validates :comments, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :one_pending_request_per_participant_team, on: :create

  scope :pending, -> { where(status: PENDING) }

  def as_json(_options = {})
    {
      id: id,
      participant_id: participant_id,
      team_id: team_id,
      assignment_id: assignment_id,
      status: status,
      comments: comments,
      response_comment: response_comment,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601
    }
  end

  private

  def one_pending_request_per_participant_team
    return unless self.class.pending.exists?(participant_id: participant_id, team_id: team_id)

    errors.add(:base, 'A pending revision request already exists for this task')
  end
end
