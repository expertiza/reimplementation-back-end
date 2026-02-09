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

    # Case 1: If participant joins a team without a topic and participant has a topic, the team gets participant's topic.
  # Case 2: If participant joins a team with a topic and participant doesn’t have a topic, participant get the team’s topic.
  # Case 3: If participant joins a team with a topic and participant has a topic, participant is warned & participant lose its topic and get the team’s topic.
  def self.update_topic_after_invite_accept(inviter_signed_up_team, invitee_signed_up_team)
    return unless inviter_signed_up_team && invitee_signed_up_team

    ActiveRecord::Base.transaction do
      inviter_topic = inviter_signed_up_team.project_topic
      invitee_topic = invitee_signed_up_team.project_topic

      # Case 1: inviter team has no topic, take invitee participant's topic
      if inviter_topic.nil? && invitee_topic.present?
        inviter_signed_up_team.update!(project_topic_id: invitee_topic.id)
      end
      #  For all cases, the invitee signed up team record need to be removed
      invitee_signed_up_team.destroy
    end
  end
end
