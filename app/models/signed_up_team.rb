# frozen_string_literal: true

class SignedUpTeam < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :team

  # Case 1: If participant joins a team without a topic and participant has a topic, the team gets participant's topic.
  # Case 2: If participant joins a team with a topic and participant doesn’t have a topic, participant get the team’s topic.
  # Case 3: If participant joins a team with a topic and participant has a topic, participant is warned & participant lose its topic and get the team’s topic.
  def self.update_topic_after_invite_accept(inviter_signed_up_team, invitee_signed_up_team)
    return unless inviter_signed_up_team && invitee_signed_up_team

    ActiveRecord::Base.transaction do
      inviter_topic = inviter_signed_up_team.sign_up_topic
      invitee_topic = invitee_signed_up_team.sign_up_topic

      # Case 1: inviter team has no topic, take invitee participant's topic
      if inviter_topic.nil? && invitee_topic.present?
        inviter_signed_up_team.update!(sign_up_topic_id: invitee_topic.id)
      end
      #  For all cases, the invitee signed up team record need to be removed
      invitee_signed_up_team.destroy
    end
  end
end