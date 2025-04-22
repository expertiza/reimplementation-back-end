module TeamOperationsHelper
   # Validates whether the given user can be part of the specified team based on its type
  def self.validate_team_membership(team, user)
    case team.type
    when 'CourseTeam'
      team.course.has_member?(user)
    when 'AssignmentTeam', 'MentoredTeam'
      team.assignment.has_member?(user)
    else
      false
    end
  end

  # Validates if the given user can be assigned as a mentor to the team
  def self.validate_mentor_assignment(team, user)
    return false unless team.is_a?(MentoredTeam)
    user.mentor?
  end

  # Copies all members from the source team to the target team
  def self.copy_team_members(source_team, target_team)
    source_team.users.each do |user|
      target_team.add_member(user)
    end
  end

  # Returns a hash of basic statistics about the given team:
  # - Current team size
  # - Maximum allowed size
  # - Whether the team is full
  # - Whether the team is empty
  def self.team_stats(team)
    {
      size: team.team_size,
      max_size: team.max_team_size,
      is_full: team.team_full?,
      is_empty: team.empty?
    }
  end
end 