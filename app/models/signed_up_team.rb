class SignedUpTeam < ApplicationRecord
  scope :confirmed, -> { where(is_waitlisted: false) }
  scope :waitlisted, -> { where(is_waitlisted: true) }

  belongs_to :project_topic
  belongs_to :team

  validates :project_topic, presence: true
  validates :team, presence: true, 
            uniqueness: { scope: :project_topic }

  def self.signup_for_topic(team, topic)
    topic.signup_team(team)
  end

  def self.remove_team_signups(team)
    team.signed_up_teams.includes(:project_topic).each do |sut|
      sut.project_topic.drop_team(team)
    end
  end
end