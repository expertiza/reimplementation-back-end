class User < ApplicationRecord
  has_secure_password
  after_initialize :set_defaults

  # name must be lowercase and unique
  validates :name, presence: true, uniqueness: true, allow_blank: false
                   # format: { with: /\A[a-z]+\z/, message: 'must be in lowercase' }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, presence: true, allow_nil: true
  validates :full_name, presence: true, length: { maximum: 50 }

  belongs_to :role
  belongs_to :institution, optional: true
  belongs_to :parent, class_name: 'User', optional: true
  has_many :users, foreign_key: 'parent_id', dependent: :nullify
  has_many :invitations
  has_many :assignments
  has_many :teams_users, dependent: :destroy
  has_many :teams, through: :teams_users
  has_many :participants

  scope :students, -> { where role_id: Role::STUDENT }
  scope :tas, -> { where role_id: Role::TEACHING_ASSISTANT }
  scope :instructors, -> { where role_id: Role::INSTRUCTOR }
  scope :administrators, -> { where role_id: Role::ADMINISTRATOR }
  scope :superadministrators, -> { where role_id: Role::SUPER_ADMINISTRATOR }

  delegate :student?, to: :role
  delegate :ta?, to: :role
  delegate :instructor?, to: :role
  delegate :administrator?, to: :role
  delegate :super_administrator?, to: :role

  def self.instantiate(record)
    case record.role
    when Role::TEACHING_ASSISTANT
      record.becomes(Ta)
    when Role::INSTRUCTOR
      record.becomes(Instructor)
    when Role::ADMINISTRATOR
      record.becomes(Administrator)
    when Role::SUPER_ADMINISTRATOR
      record.becomes(SuperAdministrator)
    else
      super
    end
  end

  # Welcome email to be sent to the user after they sign up
  def welcome_email; end

  # Return a user object if the user is found in the database, the input can be either email or name
  def self.login_user(login)
    user = User.find_by(email: login)
    if user.nil?
      short_name = login.split('@').first
      user_list = User.where(name: short_name)
      user = user_list.first if user_list.one?
    end
    user
  end

  # Reset the password for the user
  def reset_password
    random_password = SecureRandom.alphanumeric(10)
    user.password_digest = BCrypt::Password.create(random_password)
    user.save
  end

  # Get instructor_id of the user, if the user is TA,
  # return the id of the instructor else return the id of the user for superior roles
  def instructor_id
    case role
    when Role::INSTRUCTOR, Role::ADMINISTRATOR, Role::SUPER_ADMINISTRATOR
      id
    when Role::TEACHING_ASSISTANT
      my_instructor
    else
      raise NotImplementedError, "Unknown role: #{role.name}"
    end
  end

  def self.from_params(params)
    user = params[:user_id] ? User.find(params[:user_id]) : User.find_by(name: params[:user][:name])
    raise "User #{params[:user_id] || params[:user][:name]} not found" if user.nil?

    user
  end

  # This will override the default as_json method in the ApplicationRecord class and specify
  # that only the id, name, and email attributes should be included when a User object is serialized.
  def as_json(options = {})
    super(options.merge({
                          only: %i[id name email full_name email_on_review email_on_submission
                                   email_on_review_of_review],
                          include:
                          {
                            role: { only: %i[id name] },
                            parent: { only: %i[id name] },
                            institution: { only: %i[id name] }
                          }
                        })).tap do |hash|
      hash['parent'] ||= { id: nil, name: nil }
      hash['institution'] ||= { id: nil, name: nil }
    end
  end

  def set_defaults
    self.is_new_user = true
    self.copy_of_emails ||= false
    self.email_on_review ||= false
    self.email_on_submission ||= false
    self.email_on_review_of_review ||= false
    self.etc_icons_on_homepage ||= true
  end

  
  validates :reset_password_token, uniqueness: true, allow_nil: true

  # Method to generate reset password token
  def generate_password_reset_token!
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.zone.now
    save!
  end

  # Method to clear the reset token after a successful password reset
  def clear_password_reset_token!
    update(reset_password_token: nil, reset_password_sent_at: nil)
  end

  # Method to check if the password reset token is valid (within 2 hours)
  def password_reset_valid?
    (reset_password_sent_at + 2.hours) > Time.zone.now
  end

end
