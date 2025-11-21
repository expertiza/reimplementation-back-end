# frozen_string_literal: true

module TeamOperationsHelper
  # Validates whether the given user can be part of the specified team based on parent context
  def self.validate_team_membership(team, user)
    team.has_member?(user)
  end

  # Validates if the given user can be assigned as a mentor to the team
  def self.validate_mentor_assignment(team, user)
    team.is_a?(MentoredTeam) && user.mentor?
  end

  # Copies all members from the source team to the target team
  def self.copy_team_members(source_team, target_team)
    source_team.users.each do |user|
      target_team.add_member(user)
    end
  end

  # Returns a hash of basic statistics about the given team
  def self.team_stats(team)
    {
      size: team.participants.size,
      max_size: team.max_team_size,
      is_full: team.full?,
      is_empty: team.participants.empty?
    }
  end
end
