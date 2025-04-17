class SignedUpTeam < ApplicationRecord
  belongs_to :sign_up_topic
  belongs_to :team

  # Fetch all signed up teams for a given assignment id
  def self.find_team_participants(assignment_id)
    joins(:team, :sign_up_topic)
      .where(teams: { assignment_id: assignment_id })
      .select('signed_up_teams.*, teams.id as team_id, sign_up_topics.topic_name as topic_name')
  end

  # Create a signed up team
  def self.create_signed_up_team(topic_id, team_id)
    create(
      sign_up_topic_id: topic_id,
      team_id: team_id,
      is_waitlisted: false,
      preference_priority_number: 1
    )
  end

  # Find the team id of a student user
  def self.get_team_participants(user_id)
    teams_user = TeamsUser.find_by(user_id: user_id)
    teams_user&.team_id
  end

  # Delete all signed up teams for a given team id
  def self.delete_signed_up_team(team_id)
    where(team_id: team_id).destroy_all
  end
end
