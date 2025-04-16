class SignedUpTeam < ApplicationRecord
  # Scopes for filtering confirmed/waitlisted records
  scope :confirmed, -> { where(is_waitlisted: false) }
  scope :waitlisted, -> { where(is_waitlisted: true) }

  belongs_to :project_topic
  belongs_to :team

  validates :project_topic, presence: true
  validates :team, presence: true,
                   uniqueness: { scope: :project_topic }

  def self.signup_for_topic(team, topic)
    # Wrapper method to initiate team signup for a specific topic
    topic.signup_team(team)
  end

  def self.remove_team_signups(team)
    # Removes all topic associations for a team
    team.signed_up_teams.includes(:project_topic).each do |sut|
      sut.project_topic.drop_team(team)
    end
  end

  def self.find_team_participants(team_id)
    team = Team.find_by(id: team_id)
    return [] unless team

    team.users.to_a  
  end

  def self.find_team_users(team_id)
    signed_up_team = SignedUpTeam.find_by(team_id: team_id)
    return [] unless signed_up_team

    signed_up_team.team.try(:users).to_a
  end

  def self.find_user_signup_topics(user_id)
    user = User.find_by(id: user_id)
    return [] unless user

    ProjectTopic.joins(:signed_up_teams)  
                .where(signed_up_teams: { team_id: user.teams.pluck(:id) })
                .distinct.to_a
  end
end
