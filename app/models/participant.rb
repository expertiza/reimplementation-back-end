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

  def self.find_by_user_name(name)
    joins(:user).find_by(users: { name: name.strip })
  end


end
