class TeamsParticipant < ApplicationRecord
  belongs_to :participant
  belongs_to :team

  validates :participant_id, uniqueness: { scope: :team_id }
  validates :user_id, presence: true

end
