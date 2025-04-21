module TeamOperationsHelper
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

  def self.validate_mentor_assignment(team, user)
    return false unless team.is_a?(MentoredTeam)
    user.mentor?
  end

  def self.copy_team_members(source_team, target_team)
    source_team.users.each do |user|
      target_team.add_member(user)
    end
  end

  def self.team_stats(team)
    {
      size: team.team_size,
      max_size: team.max_team_size,
      is_full: team.team_full?,
      is_empty: team.empty?
    }
  end
end 