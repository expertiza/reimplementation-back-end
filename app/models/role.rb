class Role < ApplicationRecord
  validates :name, presence: true, uniqueness: true, allow_blank: false
  belongs_to :parent, class_name: 'Role', optional: true
  has_many :users, dependent: :nullify

  def super_administrator?
    name == 'Super Administrator'
  end

  def administrator?
    name == 'Administrator' || super_administrator?
  end

  def instructor?
    name == 'Instructor'
  end

  def ta?
    name == 'Teaching Assistant'
  end

  def student?
    name == 'Student'
  end

  def subordinate_roles
    role = Role.find_by(parent_id: id)
    return [] unless role

    [role] + role.subordinate_roles
  end

  def subordinate_roles_and_self
    [self] + subordinate_roles
  end

  def all_privileges_of?(target_role)
    return false if target_role.nil?

    privileges = {
      'Student' => 1,
      'Teaching Assistant' => 2,
      'Instructor' => 3,
      'Administrator' => 4,
      'Super Administrator' => 5
    }

    current_level = privileges[name]
    target_level = privileges[target_role.name]

    return false if current_level.nil? || target_level.nil?

    current_level >= target_level
  end

  def other_roles
    Role.where.not(id: id)
  end

  def as_json(options = nil)
    options ||= {}
    super(options.merge({ only: %i[id name parent_id] }))
  end
end
