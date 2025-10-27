# frozen_string_literal: true

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

  # Calls ProjectTopic's sign_team_up method to initiate signup
  # CHANGED: Updated to call sign_team_up instead of signup_team (E2552)
  def self.sign_up_for_topic(team, topic)
    topic.sign_team_up(team)
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

    find_team_participants(team_id)
  end

  # Returns project topic the given user signed up for
  def self.find_user_project_topic(user_id)
    user = User.find_by(id: user_id)
    return [] unless user

    ProjectTopic.joins(:signed_up_teams)
                .where(signed_up_teams: { team_id: user.teams.pluck(:id) })
                .distinct.to_a
  end

  # Creates a signed up team record and handles topic signup
  def self.create_signed_up_team(topic_id, team_id)
    return nil unless topic_id && team_id

    project_topic = ProjectTopic.find_by(id: topic_id)
    team = Team.find_by(id: team_id)
    
    return nil unless project_topic && team

    # Use the existing sign_up_for_topic method which calls project_topic.sign_team_up
    if sign_up_for_topic(team, project_topic)
      # Find and return the created signed up team record
      find_by(project_topic: project_topic, team: team)
    else
      nil
    end
  end

  # Deletes a signed up team and handles topic drop
  def self.delete_signed_up_team(team_id)
    team = Team.find_by(id: team_id)
    return false unless team

    # Use the existing remove_team_signups method
    remove_team_signups(team)
    true
  end

  # Gets the team ID for a given user (for student signup)
  def self.get_team_participants(user_id)
    user = User.find_by(id: user_id)
    return nil unless user

    # Get the first team the user belongs to
    user.teams.first&.id
  end
end
