class ProjectTopic < ApplicationRecord
  has_many :signed_up_teams, foreign_key: 'topic_id', dependent: :destroy
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

  def find_team_project_topics(assignment_id, team_id)
    SignedUpTeam.joins('INNER JOIN project_topics ON signed_up_teams.sign_up_topic_id = project_topics.id')
                .select('project_topics.id as topic_id, project_topics.topic_name as topic_name, signed_up_teams.is_waitlisted as is_waitlisted,
                  signed_up_teams.preference_priority_number as preference_priority_number')
                .where('project_topics.assignment_id = ? and signed_up_teams.team_id = ?', assignment_id, team_id)
  end

  # Assigns the current topic to a team by updating the provided sign-up record.
  # Marks the sign-up as not waitlisted and associates it with the current topic.
  def assign_topic_to_team(new_sign_up)
    new_sign_up.update(is_waitlisted: false, sign_up_topic_id: self.id)
  end

  # Adds a new sign-up to the waitlist by updating the sign-up record.
  # Marks the sign-up as waitlisted and associates it with the current topic.
  def save_waitlist_entry(new_sign_up)
    new_sign_up.update(is_waitlisted: true, sign_up_topic_id: self.id)
  end

  # Signs up a team for the current topic.
  # Checks if the team is already signed up, and if so, ensures they are not waitlisted.
  # If a slot is available, assigns the topic to the team; otherwise, adds the team to the waitlist.
  def sign_up_team(team_id)
    topic_id = self.id

    # Check if the team has already signed up for this topic
    existing_sign_up = SignedUpTeam.find_first_existing_sign_up(topic_id: topic_id, team_id: team_id)

    # If the team is already signed up and not waitlisted, return false
    if !existing_sign_up.nil? && !existing_sign_up.is_waitlisted
      return false
    end

    # Create a new sign-up entry for the team
    new_sign_up = SignedUpTeam.new(sign_up_topic_id: topic_id, team_id: team_id)

     # If there are available slots, assign the topic to the team and remove the team from the waitlist
    if slot_available?
      assign_topic_to_team(new_sign_up)
      result = SignedUpTeam.drop_off_team_waitlists(team_id)
    else
      # If no slots are available, add the team to the waitlist
      result = save_waitlist_entry(new_sign_up)
    end

    result
  end

  # Retrieves the team that has been waitlisted the longest for a given topic.
  # The team is selected based on the earliest created waitlist entry.
  def self.longest_waiting_team(topic_id)
    SignedUpTeam.where(sign_up_topic_id: topic_id, is_waitlisted: true).order(:created_at).first
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
      next_waitlisted_team = ProjectTopic.longest_waiting_team(self.id)
      next_waitlisted_team&.reassign_topic(self.id)
    end
    
    # Destroy the sign-up record for the team
    signed_up_team.destroy
  end

  # Retrieves all teams that are signed up for a given topic.
  def self.signed_up_teams_for_topic(topic_id)
    SignedUpTeam.where(sign_up_topic_id: topic_id)
  end

  # Calculates the number of available slots for a topic.
  # It checks how many teams have already chosen the topic and subtracts that from the maximum allowed choosers.
  def current_available_slots
    # Find the teams who have already chosen the topic and are not waitlisted
    teams_who_chose_the_topic = SignedUpTeam.where(sign_up_topic_id: self.id, is_waitlisted: false)

    # Compute the number of available slots and return
    self.max_choosers.to_i - teams_who_chose_the_topic.size
  end
end
