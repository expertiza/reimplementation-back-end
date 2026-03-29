# frozen_string_literal: true

class TeamsParticipant < ApplicationRecord
  belongs_to :participant
  belongs_to :team
  belongs_to :user

  validates :participant_id, uniqueness: true
  validates :user_id, presence: true

  validate :team_not_full, on: :create
  private
  def team_not_full
    return unless team
    
    max = team.max_size
    return if max.blank?
    
    if team.participants.count >= max
      errors.add(:base, "Team is at full capacity (max #{max}).")
    end
  end
end
