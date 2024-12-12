class ProjectTopic < ApplicationRecord
  has_many :signed_up_teams, foreign_key: :sign_up_topic_id, dependent: :destroy
  has_many :teams, through: :signed_up_teams # list all teams choose this topic, no matter in waitlist or not
  has_many :assignment_questionnaires, class_name: 'AssignmentQuestionnaire', foreign_key: 'topic_id', dependent: :destroy
  belongs_to :assignment

  # max_choosers should be a non-negative integer
  validates :max_choosers, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Checks if there are any slots currently available
  # Returns true if the number of available slots is greater than 0, otherwise false
  def slot_available?
    current_available_slots > 0
  end

  # Signs up a team for the current topic.
  # Checks if the team is already signed up, and if so, ensures they are not waitlisted.
  # If a slot is available, assigns the topic to the team; otherwise, adds the team to the waitlist.
  def sign_up_team(team_id)
    # Check if the team has already signed up for this topic
    team_signup_record = SignedUpTeam.find_by(sign_up_topic_id: self.id, team_id: team_id, is_waitlisted: false)

    # If the team is already signed up, return false
    if !team_signup_record.nil?
      return false
    end

    # Create a new sign-up entry for the team
    new_signup_record = SignedUpTeam.new(sign_up_topic_id: self.id, team_id: team_id)

     # If there are available slots, assign the topic to the team and remove the team from the waitlist
    if slot_available?
      new_signup_record.update(is_waitlisted: false, sign_up_topic_id: self.id)
      result = SignedUpTeam.drop_off_topic_waitlists(team_id)
    else
      # If no slots are available, add the team to the waitlist
      new_signup_record.update(is_waitlisted: true, sign_up_topic_id: self.id)
    end

    result
  end

  # Retrieves the team with the earliest waitlisted record for a given topic.
  # The team is determined based on the creation time of the waitlisted record.
  def longest_waiting_team
    SignedUpTeam.where(sign_up_topic_id: self.id, is_waitlisted: true).order(:created_at).first
  end

  # Removes a team from the current topic.
  # If the team is not waitlisted, the next waitlisted team is reassigned to the topic.
  # The team is then destroyed (removed from the sign-up record).
  def drop_team_from_topic(team_id)
    # Find the sign-up record for the team for this topic
    signed_up_team = SignedUpTeam.find_by(team_id: team_id, sign_up_topic_id: self.id)
    return nil unless signed_up_team

    # If the team is not waitlisted, reassign the topic to the next waitlisted team
    unless signed_up_team.is_waitlisted
      next_waitlisted_team = longest_waiting_team
      next_waitlisted_team&.reassign_topic(self.id)
    end
    
    # Destroy the sign-up record for the team
    signed_up_team.destroy
  end

  # Retrieves all teams that are signed up for a given topic.
  def signed_up_teams_for_topic
    SignedUpTeam.where(sign_up_topic_id: self.id)
  end

  # Calculates the number of available slots for a topic.
  # It checks how many teams have already chosen the topic and subtracts that from the maximum allowed choosers.
  def current_available_slots
    # Find the number of teams who have already chosen the topic and are not waitlisted
    # This would give us the number of teams who have been assigned the topic
    num_teams_registered = SignedUpTeam.where(sign_up_topic_id: self.id, is_waitlisted: false).size

    # Compute the number of available slots and return
    self.max_choosers.to_i - num_teams_registered
  end
end
