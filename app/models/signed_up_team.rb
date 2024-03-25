class SignedUpTeam < ApplicationRecord
  validates :topic_id, :team_id, presence: true
  scope :by_team_id, ->(team_id) { where('team_id = ?', team_id) }
end