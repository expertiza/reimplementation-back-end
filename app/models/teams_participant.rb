# frozen_string_literal: true

class TeamsParticipant < ApplicationRecord
  belongs_to :participant
  belongs_to :team
  belongs_to :user

  validates :participant_id, uniqueness: true
  validates :user_id, presence: true

end
