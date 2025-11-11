# frozen_string_literal: true

class SignedUpTeam < ApplicationRecord
  # Scope to return confirmed signups
  scope :confirmed, -> { where(is_waitlisted: false) }

  # Scope to return waitlisted signups
  scope :waitlisted, -> { where(is_waitlisted: true) }

  belongs_to :project_topic
  belongs_to :team

  # Validations for presence and uniqueness of team-topic pairing
  validates :project_topic, presence: true
  validates :team, presence: true,
                   uniqueness: { scope: :project_topic }

  # Calls ProjectTopic's sign_team_up method to initiate signup
  # CHANGED: Updated to call sign_team_up instead of signup_team (E2552)
  def self.sign_up_for_topic(team, topic)
    topic.sign_team_up(team)
  end

  # Removes all signups (confirmed and waitlisted) for the given team
  def self.remove_team_signups(team)
    team.signed_up_teams.includes(:project_topic).each do |sut|
      sut.project_topic.drop_team(team)
    end
  end

  # Returns all users in a given team
  def self.find_team_participants(team_id)
    team = Team.find_by(id: team_id)
    return [] unless team

    team.users.to_a
  end

  # Returns all users in a given team that's signed up for a topic
  def self.find_project_topic_team_users(team_id)
    signed_up_team = SignedUpTeam.find_by(team_id: team_id)
    return [] unless signed_up_team

    find_team_participants(team_id)
  end

  # Returns project topic the given user signed up for
  def self.find_user_project_topic(user_id)
    user = User.find_by(id: user_id)
    return [] unless user

    ProjectTopic.joins(:signed_up_teams)
                .where(signed_up_teams: { team_id: user.teams.pluck(:id) })
                .distinct.to_a
  end

  # Creates a signed up team record and handles topic signup
  def self.create_signed_up_team(topic_id, team_id)
    return nil unless topic_id && team_id

    project_topic = ProjectTopic.find_by(id: topic_id)
    team = Team.find_by(id: team_id)
    
    return nil unless project_topic && team

    # Use the existing sign_up_for_topic method which calls project_topic.sign_team_up
    if sign_up_for_topic(team, project_topic)
      # Find and return the created signed up team record
      find_by(project_topic: project_topic, team: team)
    else
      nil
    end
  end

  # Deletes a signed up team and handles topic drop
  def self.delete_signed_up_team(team_id)
    team = Team.find_by(id: team_id)
    return false unless team

    # Use the existing remove_team_signups method
    remove_team_signups(team)
    true
  end

  # Gets any team ID for a given user (legacy behavior)
  def self.get_team_participants(user_id)
    user = User.find_by(id: user_id)
    return nil unless user

    user.teams.first&.id
  end

  # Gets the user's team ID for a specific assignment (preferred for student signup)
  def self.get_team_for_assignment(user_id, assignment_id)
    user = User.find_by(id: user_id)
    return nil unless user && assignment_id

    user.teams.where(type: 'AssignmentTeam', parent_id: assignment_id).first&.id
  end

  # Ensure a student has an AssignmentTeam for the given assignment. Creates one if missing.
  def self.ensure_team_for_assignment(user_id, assignment_id)
    return nil unless user_id && assignment_id
    # If already has a team, return it
    existing_id = get_team_for_assignment(user_id, assignment_id)
    return existing_id if existing_id

    # Create a new assignment team and link the user
    team = AssignmentTeam.create!(name: "Team-#{user_id}-#{assignment_id}", parent_id: assignment_id)
    user = User.find_by(id: user_id)
    # Create or fetch assignment participant with a valid handle
    participant = AssignmentParticipant.find_or_initialize_by(user_id: user_id, parent_id: assignment_id)
    if participant.new_record?
      participant.handle = user&.handle.presence || user&.name || "user-#{user_id}"
      participant.team_id = team.id
      participant.save!
    else
      participant.update!(team_id: team.id) unless participant.team_id == team.id
    end
    TeamsParticipant.create!(team_id: team.id, user_id: user_id, participant_id: participant.id)
    team.id
  rescue StandardError
    nil
  end

  # Business logic for student signup with automatic topic switching
  def self.sign_up_student_for_topic(user_id, topic_id)
    assignment_id = ProjectTopic.find_by(id: topic_id)&.assignment_id
    team_id = get_team_for_assignment(user_id, assignment_id) || ensure_team_for_assignment(user_id, assignment_id) || get_team_participants(user_id)
    return { success: false, message: "User is not part of any team" } unless team_id

    # Drop any existing topic signups for this team
    drop_existing_signups_for_team(team_id)
    
    # Sign up for the new topic
    signed_up_team = create_signed_up_team(topic_id, team_id)
    
    if signed_up_team
      {
        success: true,
        message: "Signed up team successful!",
        signed_up_team: signed_up_team,
        available_slots: signed_up_team.project_topic.available_slots
      }
    else
      { success: false, message: "Failed to sign up for topic. Topic may be full or already signed up." }
    end
  end

  # Business logic for dropping a topic for a student
  def self.drop_topic_for_student(user_id, topic_id)
    assignment_id = ProjectTopic.find_by(id: topic_id)&.assignment_id
    team_id = get_team_for_assignment(user_id, assignment_id) || get_team_participants(user_id)
    return { success: false, message: "User is not part of any team" } unless team_id

    project_topic = ProjectTopic.find_by(id: topic_id)
    team = Team.find_by(id: team_id)
    
    return { success: false, message: "Topic or team not found" } unless project_topic && team

    signed_up_team = find_by(project_topic: project_topic, team: team)
    return { success: false, message: "Team is not signed up for this topic" } unless signed_up_team

    # Drop the team from the topic
    project_topic.drop_team(team)
    
    {
      success: true,
      message: "Successfully dropped topic!",
      available_slots: project_topic.available_slots
    }
  end

  # Business logic for admin dropping a team from a topic
  def self.drop_team_from_topic_by_admin(topic_id, team_id)
    project_topic = ProjectTopic.find_by(id: topic_id)
    team = Team.find_by(id: team_id)
    
    return { success: false, message: "Topic or team not found" } unless project_topic && team

    signed_up_team = find_by(project_topic: project_topic, team: team)
    return { success: false, message: "Team is not signed up for this topic" } unless signed_up_team

    # Drop the team from the topic
    project_topic.drop_team(team)
    
    {
      success: true,
      message: "Successfully dropped team from topic!",
      available_slots: project_topic.available_slots
    }
  end

  # Business logic for team signup
  def self.sign_up_team_for_topic(team_id, topic_id)
    signed_up_team = create_signed_up_team(topic_id, team_id)
    
    if signed_up_team
      {
        success: true,
        message: "Signed up team successful!",
        signed_up_team: signed_up_team
      }
    else
      { success: false, message: "Failed to sign up for topic" }
    end
  end

  # Business logic for updating signed up team
  def self.update_signed_up_team(id, params)
    signed_up_team = find(id)
    
    if signed_up_team.update(params)
      {
        success: true,
        message: "The team has been updated successfully.",
        signed_up_team: signed_up_team
      }
    else
      {
        success: false,
        message: signed_up_team.errors.full_messages.join(', '),
        errors: signed_up_team.errors
      }
    end
  end

  # Business logic for getting team participants for a topic
  def self.get_team_participants_for_topic(topic_id)
    project_topic = ProjectTopic.find_by(id: topic_id)
    return { success: false, message: "Topic not found" } unless project_topic

    participants = find_team_participants(project_topic.assignment_id)
    { success: true, participants: participants }
  end

  private

  # Helper method to drop existing signups for a team
  def self.drop_existing_signups_for_team(team_id)
    existing_signups = where(team_id: team_id)
    existing_signups.each do |signup|
      signup.project_topic.drop_team(signup.team)
    end
  end
end
