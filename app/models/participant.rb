class Participant < ApplicationRecord
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  belongs_to :topic, class_name: 'SignUpTopic', inverse_of: false
  has_many   :reviews, class_name: 'ResponseMap', foreign_key: 'reviewer_id', dependent: :destroy, inverse_of: false

  # Find Team based on the user.
  def team
    TeamsUser.find_by(user: user).try(:team)
  end

  def fullname
    user.fullname
  end
end