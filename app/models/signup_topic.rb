class SignupTopic < ApplicationRecord
  belongs_to :assignment
  belongs_to :waitlist, counter_cache: true
  has_many :signed_up_teams, counter_cache: true

  # Method used to destroy the topic from the table and also
  # cascading deletes performed in both SignUpTeams and Waitlist and team with error handling
  def destroy_topic()

    signed_up_teams.each do |signupteam|
      if !signupteam.destroy
        raise 'Failed to destroy SignUpTeams'+signupteam.team_id.to_s
      end
    end

    if !destroy
      raise 'Failed to destroy SignUpTopic'+@id
    end

  end

  # Method used to update the attributes that includes max_choosers, descriptions, category to the SignupTopic
  def update_topic(maxChoosers, description, category)

  end

  # Method used to retrieve participants in signed up team of particular topic.
  def find_team_participants(team_id)
    self.signed_up_teams.find(team_id).team
  end

  # Method used to return number of available slots for teams to sign up for the topic.
  def count_available_slots
    filled_slots = count_filled_slots
    total_slots = SignupTopic.find_by(topic_identifier: topic_id).max_choosers
    total_slots - filled_slots
  end

  # Method used to return the number of slots filled for the topic.
  def count_filled_slots
    self.signed_up_teams.count(:team_id)
  end

  # Method used to remove team from the topic and delegate changes to waitlist.
  def release_topic(team_id)

  end

  # Method used to validate if the topic is assigned to signed up team
  def is_assigned_to_team(team_id)

    hasassignedtopic = signed_up_teams.find(team_id).count
    hasassignedtopic.positive?
  end

  # Method used to retrieve all signed up teams for the specified topic
  def get_assigned_teams
    self.signed_up_teams
  end

  # Method used to serialize the generated output to JSON for API requests/responses.
  def serialize_to_json

  end

  def find_if_topic_available
    return true
  end

end
