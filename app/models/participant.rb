class Participant < ApplicationRecord
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  has_many   :join_team_requests, dependent: :destroy

  def fullname
    user.fullname
  end
end
