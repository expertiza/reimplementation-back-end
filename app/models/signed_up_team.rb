class SignedUpTeam < ApplicationRecord
  belongs_to :project_topic
  belongs_to :team

  def self.drop_off_team_waitlists(team_id)
    SignedUpTeam.where(team_id: team_id, is_waitlisted: true).destroy_all
  end

  def self.find_first_existing_sign_up(topic_id, team_id)
    SignedUpTeam.find_by(sign_up_topic_id: topic_id, team_id: team_id)
  end

  def self.create_signed_up_team(topic_id, team_id)
    project_topic = ProjectTopic.find_by(topic_id)
    project_topic.sign_up_team(team_id)
  end

  def self.get_team_id(user_id, assignment_id)
    team_ids = TeamsUser.select('team_id').where(user_id: user_id)
    team_id = Team.where(team_id: team_ids, assignment_id: assignment_id).first.team_id
    team_id
  end

  def self.delete_signed_up_team(team_id)
    SignedUpTeam.where(team_id: team_id).destroy_all
  end
end
