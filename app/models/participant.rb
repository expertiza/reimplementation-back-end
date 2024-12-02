class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :team, optional: true

  delegate :course, to: :assignment
  has_one   :role, foreign_key: 'role_id'

  # Validations
  validates :user_id, presence: true
  validates :assignment_id, presence: true

  # Methods
  def fullname
    user.fullname
  end
end
