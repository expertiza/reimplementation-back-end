class SignedUpTeam < ApplicationRecord
  """Scopes for filtering confirmed/waitlisted records"""
  scope :confirmed, -> { where(is_waitlisted: false) }
  scope :waitlisted, -> { where(is_waitlisted: true) }

  belongs_to :project_topic
  belongs_to :team

  validates :project_topic, presence: true
  validates :team, presence: true, 
            uniqueness: { scope: :project_topic }

  def signup_for_topic(team, topic)
    """Wrapper method to initiate team signup for a specific topic."""
    topic.signup_team(team)
  end

  def remove_team_signups(team)
    """Removes all topic associations for a team."""
    team.signed_up_teams.includes(:project_topic).each do |sut|
      sut.project_topic.drop_team(team)
    end
  end
end