class TeamsUser < ApplicationRecord
    belongs_to :user
    belongs_to :team
  
    # 2015-5-27 [zhewei]:
    # We just remove the topic_id field from the participants table.
    def self.team_id(assignment_id, user_id)
      # team_id variable represents the team_id for this user in this assignment
      team_id = nil
      teams_users = TeamsUser.where(user_id: user_id)
      teams_users.each do |teams_user|
        if teams_user.team_id == nil
          next
        end
        team = Team.find(teams_user.team_id)
        if team.parent_id == assignment_id
          team_id = teams_user.team_id
          break
        end
      end
      team_id
    end
  end
  