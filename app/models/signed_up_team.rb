class SignedUpTeam < ApplicationRecord
  # Scope to return confirmed signups
  scope :confirmed, -> { where(is_waitlisted: false) }

  # Scope to return waitlisted signups
  scope :waitlisted, -> { where(is_waitlisted: true) }

  belongs_to :project_topic
  belongs_to :team

  # Validations for presence and uniqueness of team-topic pairing
  validates :project_topic, presence: true
  validates :team, presence: true,
                   uniqueness: { scope: :project_topic }

  # Calls ProjectTopic's signup_team method to initiate signup
  def self.signup_for_topic(team, topic)
    topic.signup_team(team)
  end

  # Removes all signups (confirmed and waitlisted) for the given team
  def self.remove_team_signups(team)
    team.signed_up_teams.includes(:project_topic).each do |sut|
      sut.project_topic.drop_team(team)
    end
  end

  # Returns all users in a given team
  def self.find_team_participants(team_id)
    team = Team.find_by(id: team_id)
    return [] unless team

    team.users.to_a
  end

  # Returns all users in a given team that's signed up for a topic
  def self.find_project_topic_team_users(team_id)
    signed_up_team = SignedUpTeam.find_by(team_id: team_id)
    return [] unless signed_up_team

    signed_up_team.team.try(:users).to_a
  end

  # Returns project topic the given user signed up for
  def self.find_user_project_topic(user_id)
    user = User.find_by(id: user_id)
    return [] unless user

    ProjectTopic.joins(:signed_up_teams)
                .where(signed_up_teams: { team_id: user.teams.pluck(:id) })
                .distinct.to_a
  end
end
