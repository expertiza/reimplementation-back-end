# frozen_string_literal: true

class CourseTeam < Team
  #Each course team must belong to a course
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'

  #adds members to the course team post validation
  def add_member(user)
    # return false unless validate_membership(user)
    super(user)
  end

  # Copies the current course team to an assignment team
  # - Creates a new AssignmentTeam with a modified name
  # - Copies team members from the assignment team to the course team
  def copy_to_assignment_team(assignment)
    assignment_team = AssignmentTeam.new(
      name: "#{name} (Assignment)",
      parent_id: assignment.id
    )
    if assignment_team.save
      participants.each do |participant|
        a_participant = AssignmentParticipant.find_by(user_id: participant.user_id, parent_id: assignment.id)
        assignment_team.add_member(a_participant) if a_participant
      end
    end
    assignment_team       # Returns the newly created assignment team object
  end

  protected

  def validate_membership(user)
    # Verify user is enrolled in a course (E2610)
    CourseParticipant.exists?(user_id: user.id, parent_id: course.id)
  end

  private

  # Custom validation method for team type
  # - Ensures the type is 'CourseTeam'
  def type_must_be_course_team
    unless self.kind_of?(CourseTeam)
      errors.add(:type, 'must be CourseTeam')
    end
  end
end
