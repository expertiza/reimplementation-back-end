class SignedUpTeam < ApplicationRecord
  belongs_to :project_topic, foreign_key: :sign_up_topic_id
  belongs_to :team

  # Removes all waitlist entries for a given team.
  # This deletes all sign-up records where the team is waitlisted.
  def self.drop_off_topic_waitlists(team_id)
    SignedUpTeam.where(team_id: team_id, is_waitlisted: true).destroy_all
  end

  # Signs up a team for a specific project topic.
  # Finds the project topic by its ID and associates the given team with the topic by calling `signup_team`.
  def self.signup_team_for_topic(topic_id, team_id)
    # Find the project topic by its ID
    project_topic = ProjectTopic.find(topic_id)

    # Sign up the team for the topic
    project_topic.signup_team(team_id)
  end

  # Retrieves the team ID for a given user and assignment.
  # This first finds the team(s) the user is associated with and then retrieves the team for the specified assignment.
  # NOTE: This method is called in signed_up_teams_controller
  def self.get_team_id_for_user(user_id, assignment_id)
    # Get the team IDs associated with the given user
    team_ids = TeamsUser.select('team_id').where(user_id: user_id)

    if team_ids.empty?
      return nil
    end
    # Find the team that matches the assignment ID and retrieve its team_id
    team_id = Team.where(id: team_ids, assignment_id: assignment_id).first.id
    # Return the team ID
    team_id
  end

  # Deletes all sign-up records for a given team.
  # This removes all sign-up entries associated with the specified team.
  def self.delete_team_signup_records(team_id)
    SignedUpTeam.where(team_id: team_id).destroy_all
  end

  # Reassigns the team to a new topic by removing them from their current topic
  # and marking them as no longer waitlisted for the new topic.
  # NOTE: This method gets called only on a waitlisted team (See project_topic.rb -> drop_team_from_topic)
  def assign_topic_to_waitlisted_team(topic_id)
    # Find the team's current sign-up record where they are not waitlisted
    # As this method gets called only on a waitlisted team, we need to check if the team has been assigned another topic
    assigned_team = SignedUpTeam.find_by(team_id: self.team_id, is_waitlisted: false)

    # If the team is already assigned to a topic, remove them from that topic
    if assigned_team
      project_topic = ProjectTopic.find(assigned_team.sign_up_topic_id)
      project_topic.drop_team_from_topic(team_id: self.team_id)
    end

    # Update the team's waitlist status to false (indicating they are no longer waitlisted)
    self.update(sign_up_topic_id: topic_id, is_waitlisted: false)
  end
end
