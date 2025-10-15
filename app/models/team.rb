# frozen_string_literal: true

class Team < ApplicationRecord

  # Core associations
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy  
  has_many :teams_participants, dependent: :destroy
  has_many :users, through: :teams_participants
  has_many :participants, through: :teams_participants

  # The team is either an AssignmentTeam or a CourseTeam
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true
  belongs_to :user, optional: true # Team creator
  
  attr_accessor :max_participants
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[AssignmentTeam CourseTeam MentoredTeam], message: "must be 'Assignment' or 'Course' or 'Mentor'" }
  
  def has_member?(user)
    participants.exists?(user_id: user.id)
  end
  
  def full?
    return false unless is_a?(AssignmentTeam) && assignment&.max_team_size

    participants.count >= assignment.max_team_size
  end

  # Checks if the given participant is already on any team for the associated assignment or course.
  def participant_on_team?(participant)
    # pick the correct “scope” (assignment or course) based on this team’s class
    scope =
      if is_a?(AssignmentTeam)
        assignment
      elsif is_a?(CourseTeam)
        course
      end

    return false unless scope

    # “scope.teams” includes this team itself plus any sibling teams;
    # check whether any of those teams already has this participant
    scope.teams.any? { |team| team.participants.include?(participant) }
  end

  # Adds a participant to the team.
  # This method now expects a Participant object directly.
  def add_member(participant)
    # Fail fast if the team is already full.
    return { success: false, error: "Team is at full capacity." } if full?

    # Check if this participant is already on a team in this context.
    return { success: false, error: "Participant is already on a team for this context." } if participant_on_team?(participant)
    
    # Use create! to add the participant to the team.
    teams_participants.create!(participant: participant, user: participant.user)
    { success: true }
  rescue ActiveRecord::RecordInvalid => e
    # Catch potential validation errors from TeamsParticipant.
    { success: false, error: e.record.errors.full_messages.join(', ') }
  end

  # Determines whether a given participant is eligible to join the team.
  def can_participant_join_team?(participant)
    # figure out whether we’re in an Assignment or a Course context
    scope, participant_type, label =
      if is_a?(AssignmentTeam)
        [assignment, AssignmentParticipant, "assignment"]
      elsif is_a?(CourseTeam)
        [course, CourseParticipant, "course"]
      else
        return { success: false, error: "Team must belong to Assignment or Course" }
      end

    # Check if the user is already part of any team for this assignment or course
    if participant_on_team?(participant)
      return { success: false, error: "This user is already assigned to a team for this #{label}" }
    end

    # Check if the user is a registered participant for this assignment or course
    registered = participant_type.find_by(
      user_id: participant.user_id,
      parent_id: scope.id
    )

    unless registered
      return { success: false, error: "#{participant.user.name} is not a participant in this #{label}" }
    end

    # All checks passed; participant is eligible to join the team
    { success: true }

  end
end
