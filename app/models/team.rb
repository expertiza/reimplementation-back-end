# frozen_string_literal: true

class Team < ApplicationRecord

  # Core associations
  has_many :signed_up_teams, dependent: :destroy
  has_many :project_topics, through: :signed_up_teams
  has_many :teams_users, dependent: :destroy
  has_many :teams_participants, dependent: :destroy
  has_many :users, through: :teams_participants
  has_many :participants, through: :teams_participants
  has_many :join_team_requests, dependent: :destroy

  # The team is either an AssignmentTeam or a CourseTeam
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true
  belongs_to :user, optional: true # Team creator

  attr_accessor :max_participants
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[AssignmentTeam CourseTeam MentoredTeam], message: "must be 'Assignment' or 'Course' or 'Mentor'" }

  after_update :release_topics_if_empty

  def has_member?(user)
    participants.exists?(user_id: user.id)
  end
  
  # Returns the current number of team members
  def team_size
    users.count
  end
  
  # Concrete team types supply their parent collections and capacity policy.
  def max_size
    raise NotImplementedError, "#{self.class} must define max_size"
  end

  # Returns participants assigned to this team's assignment or course.
  def assigned_participants
    raise NotImplementedError, "#{self.class} must define assigned_participants"
  end
  
  def full?
    # Use the same limit for reporting and admission; nil means uncapped.
    maximum_team_size = max_size
    return false if maximum_team_size.nil?

    participants.count >= maximum_team_size
  end

  # Add the specified participant to the team.
  def add_member(participant)
    unless assigned_participant?(participant)
      return { success: false, error: 'Participant is not assigned to this team' }
    end

    # Sibling membership is checked by eligibility, not here: transfers add before removing.
    return { success: false, error: "Participant already on the team" } if participants.exists?(id: participant.id)
    return { success: false, error: "Unable to add participant: team is at full capacity." } if full?

    team_participant = TeamsParticipant.create(
      participant_id: participant.id,
      team_id: id,
      user_id: participant.user_id
    )

    if team_participant.persisted?
      { success: true }
    else
      { success: false, error: team_participant.errors.full_messages.join(', ') }
    end
  # Return database failures to callers while allowing programming errors to surface.
  rescue ActiveRecord::ActiveRecordError => e
    { success: false, error: e.message }
  end

  # Removes a participant from this team.
  # - Delete the TeamsParticipant join record
  # - if the participant sent any invitations while being on the team, they all need to be retracted
  # - If the team has no remaining members, destroy the team itself
  def remove_member(participant)
    # retract all the invitations the participant sent (if any) while being on the this team
    participant.retract_sent_invitations

    # Find the teams_participants record that identifies the user as belonging to this team.
    team_membership = teams_participants.find_by(participant_id: participant.id)
    team_membership&.destroy
    
    # If no participants remain after removal, delete the team
    destroy if participants.empty?
  end

  # Determines whether a given participant is eligible to join the team.
  def can_participant_join_team?(participant)
    unless assigned_participant?(participant)
      return { success: false, error: 'Participant is not assigned to this team' }
    end

    # Check this team and other teams in the same assignment or course.
    if TeamsParticipant.exists?(
      team_id: teams_of_parent.select(:id),
      participant_id: participant.id
    )
      return { success: false, error: 'Participant already belongs to a team.' }
    end

    return { success: false, error: 'The team has reached its maximum size.' } if full?

    # All checks passed; participant is eligible to join the team
    { success: true }

  end

  private

  # Returns teams in the same assignment or course, including this team.
  def teams_of_parent
    raise NotImplementedError, "#{self.class} must define teams_of_parent"
  end

  def assigned_participant?(participant)
    participant.is_a?(Participant) && participant.valid? &&
      assigned_participants.exists?(id: participant.id)
  end

  def release_topics_if_empty
    return unless participants.empty?
    project_topics.each { |topic| topic.drop_team(self) }
  end
end
