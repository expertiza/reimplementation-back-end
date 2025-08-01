class Team < ApplicationRecord

  # Core associations
  has_many :team_join_requests, dependent: :destroy
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy  
  has_many :teams_participants, dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants, through: :teams_participants

  # The team is either an AssignmentTeam or a CourseTeam
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true
  belongs_to :user, optional: true # Team creator
  
  attr_accessor :max_participants
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[AssignmentTeam CourseTeam], message: "must be 'Assignment' or 'Course'" }

  def full?
    current_size = participants.count

    # assignment teams use the column max_team_size
    if is_a?(AssignmentTeam) && assignment&.max_team_size
      return current_size >= assignment.max_team_size
    end

    # course teams never fill up by default
    false
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

  # Adds participant in the team
  def add_member(participant)
    # Check if the participant is already added to the team.
    if participants.exists?(id: participant.id)
      raise "The participant #{participant.user.name} is already a member of this team"
    end

    # Return an error hash if the team is at full capacity.
    return { success: false, error: "Unable to add participant: team is at full capacity." } if full?

    # Create the TeamsParticipant record linking the participant to the team.
    team_participant = TeamsParticipant.create(
      participant_id: participant.id,
      team_id: id,
      user_id: participant.user_id
    )
    
    if team_participant.persisted?
      { success: true }
    else
      { success: false, error: team_participant.errors.to_a.join(', ') }
    end
  rescue StandardError => e
    { success: false, error: e.message }
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
