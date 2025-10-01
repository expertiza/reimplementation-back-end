class SignedUpTeam < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :team

  # If participant join a team w/o a topic and participant have a topic, the team gets participant's topic.
  # If participant join a team w/a topic and participant doesn’t have a topic, participant get the team’s topic.
  # If participant join a team w/a topic and participant has a topic, participant is warned & participant lose its topic and get the team’s topic.
  def self.update_topic_after_invite_accept(inviter_signed_up_team, invitee_signed_up_team)
    return unless inviter_signed_up_team && invitee_signed_up_team

    ActiveRecord::Base.transaction do
      inviter_topic = inviter_signed_up_team.sign_up_topic
      invitee_topic = invitee_signed_up_team.sign_up_topic

      if inviter_topic.nil? && invitee_topic.present?
        # Case 1: inviter has no topic, take invitee's topic
        inviter_signed_up_team.update!(sign_up_topic_id: invitee_topic.id)
      end
      #  For all cases, the invitee signed up team record need to be removed
      invitee_signed_up_team.destroy
    end
  end
end