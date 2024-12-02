class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :team, optional: true

  delegate :course, to: :assignment
  belongs_to :role

  # Validations
  validates :user_id, presence: true
  validates :assignment_id, presence: true
  validates :role, presence: true
  validates :can_submit, presence: true
  validates :can_review, presence: true
  validates :can_take_quiz, presence: true
  validates :can_mentor, presence: true

  # Methods
  def fullname
    user.fullname
  end
end
