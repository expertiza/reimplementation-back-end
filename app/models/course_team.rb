# frozen_string_literal: true

class CourseTeam < Team
  #Each course team must belong to a course
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'

  # Preserve the existing policy: courses do not configure a team capacity.
  def max_size
    nil
  end

  def assigned_participants
    course ? course.participants : CourseParticipant.none
  end

  # Copies the current course team to an assignment team
  # - Creates a new AssignmentTeam with a modified name
  # - Copies team members from the assignment team to the course team
  def copy_to_assignment_team(assignment)
    assignment_team = AssignmentTeam.new(
      name: "#{name} (Assignment)",             # Appends "(Assignment)" to the team name
      assignment: assignment                    # Associates the course team with an assignment
    )
    if assignment_team.save
      participants.each do |participant|
        # Use the destination participant; capacity comes from the destination assignment.
        assignment_participant = assignment_team.assigned_participants.find_by(user_id: participant.user_id)
        assignment_team.add_member(assignment_participant)
      end
    end
    assignment_team       # Returns the newly created assignment team object
  end

  protected

  def validate_membership(user)
    # Check if user is enrolled in any assignment in the course
    course.assignments.any? { |assignment| assignment.participants.exists?(user: user) }
  end

  private

  def teams_in_parent
    course ? course.teams : CourseTeam.none
  end

  # Custom validation method for team type
  # - Ensures the type is 'CourseTeam'
  def type_must_be_course_team
    unless self.kind_of?(CourseTeam)
      errors.add(:type, 'must be CourseTeam')
    end
  end
end
