# This model handles the Topic Waitlist related activities i.e., adding teams to waitlist, queries on status of waitlist and promoting teams from waitlist.
class Waitlist
  # Return the count of teams in the waitlist for the given topic.
  def self.count_waitlisted_teams(topic_id)
    return SignedUpTeam.where(signup_topic_id: topic_id, is_waitlisted: true).count
  end
  
  # Choose the first N teams in the waitlist for promotion and delete them from the waitlist.
  def self.promote_teams_from_waitlist(topic_id, count=1)
    promotable_teams = SignedUpTeam.where(signup_topic_id: topic_id, is_waitlisted: true).limit(count).order('created_at asc');

    promoted_ids = promotable_teams.pluck(:id)
    
    promotable_teams.update_all({:is_waitlisted => false})

    return promoted_ids
end

  # Returns the IDs of the teams which are on the waitlist for the chosen topic.
  def self.get_waitlisted_teams(topic_id)
    return SignedUpTeam.where(signup_topic_id: topic_id).pluck(:id)
  end
end
