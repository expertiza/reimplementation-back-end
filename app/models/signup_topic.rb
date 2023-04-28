class SignupTopic < ApplicationRecord
  include Waitlist

  belongs_to :assignment
  has_many :signed_up_teams, counter_cache: true

  # Method used to update the attributes that includes max_choosers, descriptions, category to the SignupTopic
  def update_topic(maxChoosers = nil , description = nil, category = nil)
    need_to_update = false
    self.transaction do
      if category.present?
        self.category = category
        need_to_update = true
      end
      if description.present?
        self.description = description
        need_to_update = true
      end
      if maxChoosers.present? && maxChoosers > self.max_choosers
        count_teams_to_promote = maxChoosers - self.max_choosers
        SignupTopic.promote_teams_from_waitlist(self.id, count_teams_to_promote)
        self.max_choosers = maxChoosers
        need_to_update = true
      end
      self.save! if need_to_update
    end
  end

  # Method used to retrieve participants in signed up team of particular topic.
  def get_team_participants(team_id)
    self.signed_up_teams.find(team_id).team_participants
  end

  # Method used to return number of available slots for teams to sign up for the topic.
  def num_available_slots
    self.max_choosers - count_filled_slots
  end

  # Method used to return the number of slots filled for the topic.
  def count_filled_slots
    self.signed_up_teams.count(:team_id)
  end

  # Method used to promote 1 team from waitlist if there a signed up team is deleted.
  def promote_waitlisted_team
    self.transaction do
      return SignupTopic.promote_teams_from_waitlist(self.id)
    end
  end

  # Method used to check if the topic has been assigned to a signed up team
  def is_assigned_to_team(team_id)
    has_assigned_topic = signed_up_teams.find(team_id)
    has_assigned_topic.present?
  end

  # Method used to retrieve all signed up teams for the specified topic
  def all_assigned_teams
    self.signed_up_teams
  end

  # Method used to serialize the generated output to JSON for API requests/responses.
  def as_json
    SignupTopicSerializer.new(self).serializable_hash.to_json
  end

  # Method to check if given topic is available for selection by signup teams.
  def is_available?
    num_available_slots.positive?
  end

  # Method used to destroy the topic from the table and also
  # perform cascading deletes in SignUpTeams and Waitlist with error handling.
  def destroy_topic
    self.transaction do
      self.signed_up_teams.each do |signupteam|
        signupteam.destroy!
      end

      self.destroy!
    end
  end
end
