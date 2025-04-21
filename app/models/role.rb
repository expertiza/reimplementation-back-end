class Role < ApplicationRecord
  validates :name, presence: true, uniqueness: true, allow_blank: false
  belongs_to :parent, class_name: 'Role', optional: true
  has_many :users, dependent: :nullify

  if Role.table_exists?
    STUDENT = find_by_name('Student')
    INSTRUCTOR = find_by_name('Instructor')
    ADMINISTRATOR = find_by_name('Administrator')
    TEACHING_ASSISTANT = find_by_name('Teaching Assistant')
    SUPER_ADMINISTRATOR = find_by_name('Super Administrator')
  end


  def super_administrator?
    name['Super Administrator']
  end

  def administrator?
    name['Administrator'] || super_administrator?
  end

  def instructor?
    name['Instructor']
  end

  def ta?
    name['Teaching Assistant']
  end

  def student?
    name['Student']
  end

  # returns an array of ids of all roles that are below the current role
  def subordinate_roles
    role = Role.find_by(parent_id: id)
    return [] unless role

    [role] + role.subordinate_roles
  end

  # returns an array of ids of all roles that are below the current role and includes the current role
  def subordinate_roles_and_self
    [self] + subordinate_roles
  end

  # checks if the current role has all the privileges of the target role
  def all_privileges_of?(target_role)
    return false if target_role.nil? || name.nil?
    privileges = {
      'Student' => 1,
      'Teaching Assistant' => 2,
      'Instructor' => 3,
      'Administrator' => 4,
      'Super Administrator' => 5
    }

    privileges[name] >= privileges[target_role.name]
  end

  # return list of all roles other than the current role
  def other_roles
    Role.where.not(id:)
  end

  def as_json(options = nil)
    options = options || {} # Ensure options is a hash
    super(options.merge({ only: %i[id name parent_id] }))
  end
end
