class TeamsParticipant < ApplicationRecord
  belongs_to :participant
  belongs_to :team

  validates :participant_id, uniqueness: { scope: :team_id }

  # Returns the name of the associated user
  def name
    participant.user.name
  end

end
