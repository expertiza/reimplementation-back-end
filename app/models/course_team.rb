# frozen_string_literal: true

class CourseTeam < Team
  # Each course team must belong to a course
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'

  # === Implementation of Abstract Methods ===

  def parent_entity
    course
  end

  def participant_class
    CourseParticipant
  end

  def context_label
    'course'
  end

  # === Copying Logic ===

  # Copies the current course team to an assignment team
  def copy_to_assignment_team(assignment)
    assignment_team = AssignmentTeam.new(
      name: name, # Keep the same name by default
      parent_id: assignment.id
    )

    if assignment_team.save
      # Use the protected method from the base Team class
      copy_members_to_team(assignment_team)
    end

    assignment_team
  end

  # Copies the current course team to another course team
  def copy_to_course_team(target_course)
    new_team = CourseTeam.new(
      name: name, # Keep the same name by default
      parent_id: target_course.id
    )

    if new_team.save
      # Use the protected method from the base Team class
      copy_members_to_team(new_team)
    end

    new_team
  end
end
