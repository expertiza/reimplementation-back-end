class Waitlist < ApplicationRecord
  belongs_to :signup_topic
  belongs_to :signed_up_team

  def self.count_waitlisted_teams(topic_id)
    return Waitlist.where(signup_topic_id: topic_id).count
  end

  def self.remove_teams_from_waitlist(topic_id, team_ids)
    items_to_delete = Waitlist.where(signup_topic_id: topic_id, signed_up_team_id: team_ids)

    deleted_item_count = items_to_delete.size
    items_to_delete.destroy_all
    return deleted_item_count
  end

  def self.promote_teams_from_waitlist(topic_id, count=1)
    teams_in_waitlist = Waitlist.where(signup_topic_id: topic_id).limit(count).order('created_at asc').pluck(:signed_up_team_id);

    Waitlist.where(signed_up_team_id: teams_in_waitlist).destroy_all

    return teams_in_waitlist
  end

  def self.get_waitlisted_teams(topic_id)
    return Waitlist.where(signup_topic_id: topic_id).pluck(:signed_up_team_id)
  end
end
