class AccountRequest < ApplicationRecord
  belongs_to :role
  belongs_to :institution

  before_save { self.email = email.downcase }
  before_save { username }

  validates :username, presence: true, length: { maximum: 50, message: 'is too long' },
                       format: { with: /\A[a-z]+\z/, message: 'must be in lowercase without numbers or special chars' }

  validates :email, presence: true, length: { maximum: 255, message: 'is too long' },
                    format: { with: URI::MailTo::EMAIL_REGEXP, message: 'format is wrong' }

  validates :full_name, presence: true, length: { maximum: 100, message: 'is too long' }

  validate :validate_user_exists, on: :create

  private

  # Check if user with same username or email already exists in Users table
  def validate_user_exists
    return unless User.find_by(name: self[:username])

    errors.add(:username, 'User with this username already exists')
  end
end
