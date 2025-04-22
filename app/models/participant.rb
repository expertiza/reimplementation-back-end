class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :team, optional: true
  has_many   :reviews, class_name: 'ResponseMap', foreign_key: 'reviewer_id', dependent: :destroy, inverse_of: false

  delegate :course, to: :assignment

  # Validations
  validates :user_id, presence: true
  validates :assignment_id, presence: true
  validates :grade, numericality: { allow_nil: true }

  # Methods
  def fullname
    user.fullname
  end
end
