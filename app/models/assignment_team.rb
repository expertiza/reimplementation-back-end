# frozen_string_literal: true

class AssignmentTeam < Team
  # Each AssignmentTeam must belong to a specific assignment
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'

  # Implement abstract methods from Team
  def parent_entity
    assignment
  end

  def participant_class
    AssignmentParticipant
  end

  def context_label
    'assignment'
  end

  # Override max_team_size to pull from assignment
  def max_team_size
    assignment&.max_team_size
  end

  # Copies the current assignment team to a course team
  def copy_to_course_team(course)
    course_team = CourseTeam.new(
      name: "#{name} (Course)",
      parent_id: course.id
    )
    
    if course_team.save
      copy_members_to_team(course_team, course)
    end
    
    course_team
  end

  # Copies the current assignment team to another assignment team
  def copy_to_assignment_team(target_assignment)
    new_team = AssignmentTeam.new(
      name: "#{name} (Copy)",
      parent_id: target_assignment.id
    )
    
    if new_team.save
      copy_members_to_team(new_team, target_assignment)
    end
    
    new_team
  end

  protected

  def validate_membership(user)
    assignment.participants.exists?(user: user)
  end

  private

  def copy_members_to_team(target_team, target_parent)
    participants.each do |assignment_participant|
      # Find or create corresponding participant in target context
      target_participant = target_team.participant_class.find_or_create_by!(
        user_id: assignment_participant.user_id,
        parent_id: target_parent.id
      ) do |p|
        p.handle = assignment_participant.handle
      end
      
      target_team.add_member(target_participant)
    end
  end
end
