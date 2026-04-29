# frozen_string_literal: true

class TeamsParticipant < ApplicationRecord
  belongs_to :participant
  belongs_to :team
  belongs_to :user

  validates :participant_id, uniqueness: { scope: :team_id }
  validates :user_id, presence: true

  def resolved_duty
    Duty.find_by(id: duty_id) || Duty.find_by(id: participant&.duty_id)
  end

  def allows_review?
    duty_allows?(%w[participant reader reviewer mentor])
  end

  def allows_quiz?
    duty_allows?(%w[participant reader mentor])
  end

  private

  def duty_allows?(allowed_duties)
    duty = resolved_duty
    return false if duty.nil?

    duty.name.in?(allowed_duties)
  end
end
