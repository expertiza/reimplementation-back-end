class SignupTopic < ApplicationRecord
  belongs_to :assignment

  def release_topic(team_id)
    return true
  end

  def find_if_topic_available()
    return true
  end
end
