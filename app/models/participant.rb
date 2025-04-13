class Participant < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :assignment, foreign_key: 'assignment_id', inverse_of: false
  belongs_to :course, foreign_key: 'course_id', inverse_of: false
  has_many   :join_team_requests, dependent: :destroy
  belongs_to :team, optional: true

  delegate :course, to: :assignment

  # Validations
  validates :user_id, presence: true
  # validates :assignment_id, presence: true
  # Validation: require one of them
  validate :assignment_or_course_presence

  # Methods
  def fullname
    user.fullname
  end

  def self.find_by_user_name(name)
    joins(:user).find_by(users: { name: name.strip })
  end

  private

  def assignment_or_course_presence
    if assignment_id.blank? && course_id.blank?
      errors.add(:base, "Either assignment or course must be present")
    end
  end


end
