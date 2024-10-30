class ProjectTopic < ApplicationRecord
  has_many :signed_up_teams, foreign_key: 'topic_id', dependent: :destroy
  has_many :teams, through: :signed_up_teams # list all teams choose this topic, no matter in waitlist or not
  has_many :assignment_questionnaires, class_name: 'AssignmentQuestionnaire', foreign_key: 'topic_id', dependent: :destroy
  belongs_to :assignment

  def slot_available?
    topic_id = self.id

    # Find the teams who have chosen the topic
    teams_who_chose_the_topic = SignedUpTeam.where(sign_up_topic_id: topic_id, is_waitlisted: false)

    # Check if no teams have chosen the topic yet
    if teams_who_chose_the_topic.nil?
      return true
    else
      # Check if the number of teams who chose the topic is less than the max allowed and return
      return teams_who_chose_the_topic.size < self.max_choosers
    end
  end

  def find_team_project_topics(assignment_id, team_id)
    SignedUpTeam.joins('INNER JOIN project_topics ON signed_up_teams.sign_up_topic_id = project_topics.id')
                .select('project_topics.id as topic_id, project_topics.topic_name as topic_name, signed_up_teams.is_waitlisted as is_waitlisted,
                  signed_up_teams.preference_priority_number as preference_priority_number')
                .where('project_topics.assignment_id = ? and signed_up_teams.team_id = ?', assignment_id, team_id)
  end

  def assign_topic_to_team(new_sign_up)
    new_sign_up.update(is_waitlisted: false, sign_up_topic_id: self.id)
  end

  def save_waitlist_entry(new_sign_up)
    new_sign_up.is_waitlisted = true
    new_sign_up.sign_up_topic_id = self.id
    result = new_sign_up.save
    result
  end

  def sign_up_team(team_id)
    topic_id = self.id
    team = Team.find(team_id)

    existing_sign_up = SignedUpTeam.find_first_existing_sign_up(topic_id: topic_id, team_id: team_id)

    if !existing_sign_up.nil? && !existing_sign_up.is_waitlisted
      return false
    end

    new_sign_up = SignedUpTeam.new(sign_up_topic_id: topic_id, team_id: team_id)
    if slot_available?
      assign_topic_to_team(new_sign_up)
      result = SignedUpTeam.drop_off_team_waitlists(team_id)
    else
      result = save_waitlist_entry(new_sign_up)
    end
    result
  end
end
