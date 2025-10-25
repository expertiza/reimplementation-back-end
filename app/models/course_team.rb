# frozen_string_literal: true

class CourseTeam < Team
  #Each course team must belong to a course
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id'

  # Implement abstract methods from Team
  def parent_entity
    course
  end

  def participant_class
    CourseParticipant
  end

  def context_label
    'course'
  end

  # Copies the current course team to an assignment team
  def copy_to_assignment_team(assignment)
    assignment_team = AssignmentTeam.new(
      name: "#{name} (Assignment)",
      parent_id: assignment.id
    )
    
    if assignment_team.save
      copy_members_to_team(assignment_team, assignment)
    end
    
    assignment_team
  end

  # Copies the current course team to another course team
  def copy_to_course_team(target_course)
    new_team = CourseTeam.new(
      name: "#{name} (Copy)",
      parent_id: target_course.id
    )
    
    if new_team.save
      copy_members_to_team(new_team, target_course)
    end
    
    new_team
  end

  protected

  def validate_membership(user)
    course.participants.exists?(user: user)
  end

  private


end
