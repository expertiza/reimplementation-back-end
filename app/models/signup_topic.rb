class SignupTopic < ApplicationRecord
  belongs_to :assignment

  def release_team(team_id)
    return true
  end

  def is_available()
    return true
  end
end
