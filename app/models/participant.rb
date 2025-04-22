class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :team, optional: true

  delegate :course, to: :assignment

  # Validations
  validates :user_id, presence: true
  validates :assignment_id, presence: true

  # Methods
  def fullname
    user.fullname
  end

  # Check if the participant can review in this assignment
  # @return [Boolean] true if the participant can review, false otherwise
  def can_review?
    # For now, all participants can review
    # This can be extended with more complex logic if needed
    true
  end
end
