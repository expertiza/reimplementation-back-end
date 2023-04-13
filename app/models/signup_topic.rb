class SignupTopic < ApplicationRecord
  belongs_to :assignment
  belongs_to :waitlist, counter_cache: true
  has_many :signed_up_teams, counter_cache: true

  # Method used to destroy the topic from the table and also
  # cascading deletes performed in both SignUpTeams and Waitlist and team with error handling
  def destroy_topic(topic_identifier_)

  end

  # Method used to update the attributes that includes max_choosers, descriptions, category to the SignupTopic
  def update_topic(topic_identifier_, max_choosers_, description_, category_)

  end

  # Method used to retrieve participants in signed up team of particular topic.
  def find_team_participants(topic_identifier_, team_id_)

  end

  # Method used to return number of available slots for teams to sign up for the topic.
  def count_available_slots(topic_id)

  end

  # Method used to return the number of slots filled for the topic.
  def count_filled_slots(topic_id)

  end

  # Method used to remove team from the topic and delegate changes to waitlist.
  def release_topic(team_id_, topic_identifier_)

  end

  # Method used to validate if the topic is assigned to signed up team
  def is_assigned_to_team(topic_identifier_, team_id_)

  end

  # Method used to retrieve all signed up teams for the specified topic
  def get_assigned_teams(topic_identifier_)

  end

  # Method used to serialize the generated output to JSON for API requests/responses.
  def serialize_to_json()

  end

end
