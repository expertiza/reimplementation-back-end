class SignedUpTeam < ApplicationRecord
  belongs_to :project_topic
  belongs_to :team

  # Removes all waitlist entries for a given team.
  # This deletes all sign-up records where the team is waitlisted.
  def self.drop_off_team_waitlists(team_id)
    SignedUpTeam.where(team_id: team_id, is_waitlisted: true).destroy_all
  end

  # Creates a sign-up record for a team by associating the team with the given topic.
  # This finds the project topic by its ID and then calls the `sign_up_team` method to sign the team up.
  def self.create_signed_up_team(topic_id, team_id)
    # Find the project topic by its ID
    project_topic = ProjectTopic.find(topic_id)

    # Sign up the team for the topic
    project_topic.sign_up_team(team_id)
  end

  # Retrieves the team ID for a given user and assignment.
  # This first finds the team(s) the user is associated with and then retrieves the team for the specified assignment.
  def self.get_team_id(user_id, assignment_id)
    # Get the team IDs associated with the given user
    team_ids = TeamsUser.select('team_id').where(user_id: user_id)
    # Find the team that matches the assignment ID and retrieve its team_id
    team_id = Team.where(team_id: team_ids, assignment_id: assignment_id).first.team_id
    # Return the team ID
    team_id
  end

  # Deletes all sign-up records for a given team.
  # This removes all sign-up entries associated with the specified team.
  def self.drop_off_team_signup_records(team_id)
    SignedUpTeam.where(team_id: team_id).destroy_all
  end

  # Reassigns the team to a new topic by removing them from their current topic
  # and marking them as no longer waitlisted for the new topic.
  def reassign_topic(topic_id)
    # Find the team's current sign-up record where they are not waitlisted
    assigned_team = SignedUpTeam.where(team_id: self.team_id, is_waitlisted: false)

    # If the team is already assigned to a topic, remove them from that topic
    unless assigned_team.nil?
      project_topic = ProjectTopic.find(topic_id)
      project_topic.drop_team_from_topic(team_id: self.team_id)
    end

    # Update the team's waitlist status to false (indicating they are no longer waitlisted)
    self.update(is_waitlisted: false)
  end
end
