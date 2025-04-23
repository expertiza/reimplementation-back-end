class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :team, optional: true
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id', optional: true, inverse_of: :participants
  belongs_to :course, class_name: 'Course', foreign_key: 'parent_id', optional: true, inverse_of: :participants

  # Validations
  validates :user_id, presence: true
  validates :parent_id, presence: true
  validates :type, presence: true, inclusion: { in: %w[AssignmentParticipant CourseParticipant], message: "must be either 'AssignmentParticipant' or 'CourseParticipant'" }

  # Methods
  def fullname
    user.fullname
  end



end
