class Waitlist < ApplicationRecord
  belongs_to :signup_topic
  belongs_to :signed_up_team

  def self.count_waitlisted_teams(topic_id)
    return Waitlist.where(signup_topic_id: topic_id).count
  end

  def self.remove_teams_from_waitlist()
    # TODO: Remove teams from the waitlist.
  end

  def self.get_waitlisted_teams(topic_id)
    return Waitlist.where(signup_topic_id: topic_id).pluck(:signed_up_team_id)
  end
end
