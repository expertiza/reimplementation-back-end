class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :team_participants, dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants

  # The team is either an AssignmentTeam or a CourseTeam
  belongs_to :assignment, optional: true
  belongs_to :course, optional: true
  attr_accessor :max_participants

  # Custom validation to enforce presence of exactly one association for AssignmentTeam or CourseTeam
  validate :exactly_one_association



  # TODO Team implementing Teams controller and model should implement this method better.
  # TODO partial implementation here just for the functionality needed for join_team_tequests controller
  def full?

    max_participants ||= 3
    if participants.count >= max_participants
      true
    else
      false
    end
  end


  # Checks if the given participant is already on any team for the associated assignment or course.
  def participant_on_team?(participant)
    if respond_to?(:assignment) && assignment.present?
      # For an assignment team, check all teams of the assignment.
      assignment.teams.flat_map(&:participants).include?(participant)
    elsif respond_to?(:course) && course.present?
      # For a course team, check all teams of the course.
      course.teams.flat_map(&:participants).include?(participant)
    end
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
    # Determine the team context (assignment or course), or return failure if undefined
    context = if respond_to?(:assignment) && assignment.present?
                { scope: assignment, participant_model: AssignmentParticipant, label: "assignment" }
              elsif respond_to?(:course) && course.present?
                { scope: course, participant_model: CourseParticipant, label: "course" }
              else
                return { success: false, error: "Team is neither an assignment team nor a course team" }
              end

    # Check if the user is already part of any team for this assignment or course
    return { success: false, error: "This user is already assigned to a team for this #{context[:label]}" } if participant_on_team?(participant)

    # Check if the user is a registered participant for this assignment or course
    registered = context[:participant_model].find_by(user_id: participant.user_id, "#{context[:label]}_id": context[:scope].id)
    return { success: false, error: "#{participant.user.name} is not a participant in this #{context[:label]}" } if registered.nil?

    # All checks passed; participant is eligible to join the team
    { success: true }

  end

  private

  def exactly_one_association
    if assignment_id.blank? && course_id.blank?
      errors.add(:base, "Team must belong to either an assignment or a course")
    elsif assignment_id.present? && course_id.present?
      errors.add(:base, "Team cannot be both AssignmentTeam and a CourseTeam")
    end
  end


end
