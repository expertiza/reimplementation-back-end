class AccountRequest < ApplicationRecord
    belongs_to :role
    belongs_to :institution
  
    before_save { self.email = email.downcase }
    before_save { name }
    
    validates :name, presence: true, length: { maximum: 50, message: 'is too long' },
                     uniqueness: { case_sensitive: false, message: 'Account with this name has already been requested' }
    validates :email, presence: true, length: { maximum: 255, message: 'is too long' },
                      format: { with: URI::MailTo::EMAIL_REGEXP, message: 'format is wrong' },
                      uniqueness: { case_sensitive: false, message: 'Account with this emaill has already been requested' }
  
    validates :fullname, presence: true, length: { maximum: 100, message: 'is too long' }

    validate :validate_user_exists, on: :create

    private

    # Check if user with same name or email already exists in Users table
    def validate_user_exists
        if User.find_by(name: self[:name])
            self.errors.add(:name, 'User with this name already exists')
        elsif User.find_by(email: self[:email])
            self.errors.add(:email, 'User with this email already exists')
        end
    end
  end
  