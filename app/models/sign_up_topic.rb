class SignUpTopic < ApplicationRecord
  belongs_to :assignment
  # has_many :signed_up_team
  validates_uniqueness_of :topic_name, scope: :assignment_id


  def release_team(team_id)
    return true
  end

  def is_available()
    return true
  end
end