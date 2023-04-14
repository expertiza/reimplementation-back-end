# This model handles the Topic Waitlist related activities i.e., adding teams to waitlist, queries on status of waitlist and promoting teams from waitlist.
class Waitlist
  # Return the count of teams in the waitlist for the given topic.
  def self.count_waitlisted_teams(topic_id)
    return Waitlist.where(signup_topic_id: topic_id).count
  end
  
  # Remove chosen teams from the waitlist for the given topic id.
  # NOTE: This is required during the un-register process where teams can drop a topic while they are on the waitlist.
  def self.remove_teams_from_waitlist(topic_id, team_ids)
    items_to_delete = Waitlist.where(signup_topic_id: topic_id, signed_up_team_id: team_ids)

    deleted_item_count = items_to_delete.size
    items_to_delete.destroy_all
    return deleted_item_count
  end
  
  # Choose the first N teams in the waitlist for promotion and delete them from the waitlist.
  def self.promote_teams_from_waitlist(topic_id, count=1)
    promotable_teams = Waitlist.where(signup_topic_id: topic_id)
                          .limit(count)
                          .order('created_at asc')
                          .pluck(:signed_up_team_id);

    Waitlist.where(signed_up_team_id: promotable_teams).destroy_all
    return promotable_teams
  end

  # Returns the IDs of the teams which are on the waitlist for the chosen topic.
  def self.get_waitlisted_teams(topic_id)
    return Waitlist.where(signup_topic_id: topic_id).pluck(:signed_up_team_id)
  end
end
