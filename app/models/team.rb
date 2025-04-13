class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_users, dependent: :destroy
  has_many :team_participants, dependent: :destroy
  has_many :users, through: :teams_users
  has_many :participants
  belongs_to :assignment
  belongs_to :course
  attr_accessor :max_participants

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



  # Add participant in the team
  def add_member(participant)
    # Check if the participant is already added to the team.
    if participants.exists?(id: participant.id)
      raise "The participant #{participant.user.name} is already a member of this team"
    end

    # Return an error hash if the team is at full capacity.
    return { success: false, error: "Unable to add participant: team is at full capacity." } if full?

    # Create the TeamParticipant record linking the participant to the team.
    team_participant = TeamParticipant.create(participant_id: participant.id, team_id: id)

    if team_participant.persisted?
      { success: true }
    else
      { success: false, error: team_participant.errors.to_a.join(', ') }
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end



  def can_participant_join_team?(participant)

    if respond_to?(:assignment) && assignment.present?
      # Check if the user is already part of a team for this assignment.
      if participant_on_team?(participant)
        { success: false, error: "This user is already assigned to a team for this assignment" }

      # Check if the user is a registered participant in the assignment.
      elsif AssignmentParticipant.find_by(user_id: participant.user_id, assignment_id: assignment.id).nil?
        { success: false, error: "#{participant.user.name} is not a participant in this assignment" }

      # If both checks pass, the participant is eligible to join the team.
      else
        { success: true }
      end

    # If team is not an AssignmentTeam, then it is a CourseTeam

    elsif respond_to?(:course) && course.present?
      # Check if the user is already part of a team for this course.
      if participant_on_team?(participant)
        { success: false, error: "This user is already assigned to a team for this course" }

      # Check if the user is a registered participant in the course.
      elsif CourseParticipant.find_by(user_id: participant.user_id, course_id: course.id).nil?
        { success: false, error: "#{participant.user.name} is not a participant in this course" }

        # If both checks pass, the participant is eligible to join the team.
      else
        { success: true }
      end

    end
  end


end
