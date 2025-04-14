class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', optional: true, inverse_of: false
  belongs_to :course, foreign_key: 'course_id', optional: true, inverse_of: false
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :team, optional: true

  # delegate :course, to: :assignment, allow_nil: true

  # Validations
  validates :user_id, presence: true
  # Validation: require either assignment_id or course_id
  validate :assignment_or_course_presence

  # Methods
  def fullname
    user.fullname
  end


  private

  def assignment_or_course_presence
    if assignment.blank? && course.blank?
      errors.add(:base, "Either assignment or course must be present")
    elsif assignment.present? && course.present?
      errors.add(:base, "A Participant cannot be both an AssignmentParticipant and a CourseParticipant.")
    end
  end


end
