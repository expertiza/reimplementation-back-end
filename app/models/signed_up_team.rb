class SignedUpTeam < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :team

  def self.topic_id(assignment_id, user_id)
    # team_id variable represents the team_id for this user in this assignment
    team_id = TeamsUser.team_id(assignment_id, user_id)
    topic_id_by_team_id(team_id) if team_id
  end

  def self.topic_id_by_team_id(team_id)
    signed_up_teams = SignedUpTeam.where(team_id: team_id, is_waitlisted: 0)
    if signed_up_teams.blank?
      nil
    else
      signed_up_teams.first.topic_id
    end
  end
end
