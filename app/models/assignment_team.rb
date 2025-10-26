# frozen_string_literal: true

class AssignmentTeam < Team
  # Each AssignmentTeam must belong to a specific assignment
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'

  # === Implementation of Abstract Methods ===

  def parent_entity
    assignment
  end

  def participant_class
    AssignmentParticipant
  end

  def context_label
    'assignment'
  end

  # === Overridden Methods ===

  # Override max_team_size to pull from assignment
  def max_team_size
    assignment&.max_team_size
  end

  # === Copying Logic ===

  # Copies the current assignment team to a course team
  def copy_to_course_team(course)
    course_team = CourseTeam.new(
      name: name, # Keep the same name by default
      parent_id: course.id
    )

    if course_team.save
      # Use the protected method from the base Team class
      copy_members_to_team(course_team)
    end

    course_team
  end

  # Copies the current assignment team to another assignment team
  def copy_to_assignment_team(target_assignment)
    new_team = self.class.new( # Use self.class to support MentoredTeam
      name: name, # Keep the same name by default
      parent_id: target_assignment.id
    )

    if new_team.save
      # Use the protected method from the base Team class
      copy_members_to_team(new_team)
    end

    new_team
  end
end
