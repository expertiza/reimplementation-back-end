# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  after_initialize :set_defaults

  # name must be lowercase and unique
  validates :name, presence: true, uniqueness: true, allow_blank: false
                   # format: { with: /\A[a-z]+\z/, message: 'must be in lowercase' }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, if: :password_required?
  validates :password, length: { minimum: 6 }, allow_nil: true
  validates :full_name, presence: true, length: { maximum: 50 }

  belongs_to :role
  belongs_to :institution, optional: true
  belongs_to :parent, class_name: 'User', optional: true
  has_many :users, foreign_key: 'parent_id', dependent: :nullify

  # Looking at invitation.rb, invitations relate to users only through participants.
  # (from_id and to_id both point to AssignmentParticipant, not User).
  # There is no user foreign key on the invitations table at all.
  # has_many :invitations
  has_many :participants

  # A user participates in assignments via the participants join table
  has_many :assignments, through: :participants

  # A user can also be the instructor of many assignments directly
  # via instructor_id on the assignments table
  has_many :instructed_assignments, class_name: 'Assignment', foreign_key: 'instructor_id'
  has_many :teams_users, dependent: :destroy
  has_many :teams, through: :teams_users
  
  #join on role name instead of hardcoded IDs, matching create_roles_heirarchy
  scope :students,           -> { joins(:role).where(roles: { name: 'Student' }) }
  scope :tas,                -> { joins(:role).where(roles: { name: 'Teaching Assistant' }) }
  scope :instructors,        -> { joins(:role).where(roles: { name: 'Instructor' }) }
  scope :administrators,     -> { joins(:role).where(roles: { name: 'Administrator' }) }
  scope :superadministrators,-> { joins(:role).where(roles: { name: 'Super Administrator' }) }

  delegate :student?, to: :role
  delegate :ta?, to: :role
  delegate :instructor?, to: :role
  delegate :administrator?, to: :role
  delegate :super_administrator?, to: :role

  def self.instantiate(record)
    case record.role.name
    when /Super Administrator/
      record.becomes(SuperAdministrator)
    when /Teaching Assistant/
      record.becomes(Ta)
    when /Instructor/
      record.becomes(Instructor)
    when /Administrator/
      record.becomes(Administrator)
    else
      # Student or other roles remain as User
      record
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
    self.password = random_password
    save
  end

  def password_required?
    password_digest.blank? || !password.nil?
  end

  # Get instructor_id of the user, if the user is TA,
  # return the id of the instructor else return the id of the user for superior roles
  def instructor_id
    case role.name
    when /Instructor/, /Administrator/, /Super Administrator/
      id
    when /Teaching Assistant/
      Ta.find(id).my_instructor
    else
      raise NotImplementedError, "Unknown role: #{role.name}"
    end
  end

  def can_impersonate?(user)
    return true if role.super_administrator?
    return true if teaching_assistant_for?(user)
    return true if recursively_parent_of(user)

    false
  end

  def recursively_parent_of(user)
    p = user.parent
    return false if p.nil?
    return true if p == self
    return false if p.role.super_administrator?

    recursively_parent_of(p)
  end

  def teaching_assistant_for?(student)
    return false unless teaching_assistant?
    return false unless student.role.name == 'Student'

    ta = Ta.find(id)
    ta.courses_assisted_with.any? do |c|
      c.assignments.map(&:participants).flatten.map(&:user_id).include? student.id
    end
  end

  def teaching_assistant?
    !!role.ta?
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
      hash['parent'] ||= { 'id' => nil, 'name' => nil }
      hash['institution'] ||= { 'id' => nil, 'name' => nil }
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

  def generate_jwt
    JWT.encode({ id: id, exp: 60.days.from_now.to_i }, Rails.application.credentials.secret_key_base, 'HS256')
  end

end
