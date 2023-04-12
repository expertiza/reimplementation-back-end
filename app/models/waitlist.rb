class Waitlist < ApplicationRecord
  belongs_to :signup_topic
  belongs_to :signed_up_team

  def self.count_waitlisted_teams(topic_id)
    return Waitlist.where(sign_up_topic_id: topic_id).count
  end

  def self.remove_teams_from_waitlist()
    # TODO: Remove teams from the waitlist.
  end

  def self.add_teams_to_waitlist()
    # TODO: Add teams to the waitlist.
  end

  def self.get_waitlisted_teams()
    # TODO: Get all the waitlisted teams
  end
end
