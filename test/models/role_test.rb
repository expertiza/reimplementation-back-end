require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  test 'validations' do
    role = Role.new(name: nil)
    assert_not role.valid?
    assert_equal ["can't be blank"], role.errors[:name]

    role.name = 'Administrator'
    assert role.save

    new_role = Role.new(name: 'Administrator')
    assert_not new_role.valid?
    assert_equal ['has already been taken'], new_role.errors[:name]
  end

  test 'instance methods' do
    super_admin_role = Role.create!(name: 'Super Administrator')
    admin_role = Role.create!(name: 'Administrator')
    instructor_role = Role.create!(name: 'Instructor')
    ta_role = Role.create!(name: 'Teaching Assistant')
    student_role = Role.create!(name: 'Student')

    assert super_admin_role.super_admin?
    assert_not admin_role.super_admin?

    assert super_admin_role.admin?
    assert admin_role.admin?
    assert_not instructor_role.admin?

    assert instructor_role.instructor?
    assert_not ta_role.instructor?

    assert ta_role.ta?
    assert_not student_role.ta?

    assert student_role.student?
    assert_not super_admin_role.student?

    child1 = Role.create!(name: 'Child1')
    child2 = Role.create!(name: 'Child2', parent: child1)
    parent = Role.create!(name: 'Parent', parent: child2)

    assert_equal [child2.id, child1.id], parent.subordinate_roles
  end

  test 'subordinate_roles_and_self' do
    child1 = Role.create!(name: 'Child1')
    child2 = Role.create!(name: 'Child2', parent: child1)
    parent = Role.create!(name: 'Parent', parent: child2)

    assert_equal [parent.id, child1.id, child2.id].sort, parent.subordinate_roles_and_self.sort,
                 'a higher role should have all lesser roles and itself'
    assert_equal [child1.id, child2.id].sort, child2.subordinate_roles_and_self.sort,
                 'a higher role should have all lesser roles and itself'
  end

  test 'all_privileges_of?' do
    super_admin_role = Role.create!(name: 'Super Administrator')
    admin_role = Role.create!(name: 'Administrator')
    instructor_role = Role.create!(name: 'Instructor')
    ta_role = Role.create!(name: 'Teaching Assistant')
    student_role = Role.create!(name: 'Student')

    assert super_admin_role.all_privileges_of?(admin_role)
    assert_not admin_role.all_privileges_of?(super_admin_role)

    assert admin_role.all_privileges_of?(instructor_role)
    assert_not instructor_role.all_privileges_of?(admin_role)

    assert instructor_role.all_privileges_of?(ta_role)
    assert_not ta_role.all_privileges_of?(instructor_role)

    assert ta_role.all_privileges_of?(student_role)
    assert_not student_role.all_privileges_of?(ta_role)
  end

  test 'other_roles' do
    role1 = Role.create!(name: 'Role1')
    role2 = Role.create!(name: 'Role2')
    role3 = Role.create!(name: 'Role3')

    other_roles = role1.other_roles
    assert_includes other_roles, role2
    assert_includes other_roles, role3
    assert_not_includes other_roles, role1
  end

  # Test for invalid role name length
  test 'validates name length' do
    role = Role.new(name: 'A' * 51) # assuming max length is 50
    assert_not role.valid?
    assert_equal ['is too long (maximum is 50 characters)'], role.errors[:name]

    role.name = 'A' * 2 # assuming min length is 3
    assert_not role.valid?
    assert_equal ['is too short (minimum is 3 characters)'], role.errors[:name]
  end

  # Test for role parent-child relationships
  test 'parent-child relationship' do
    parent_role = Role.create!(name: 'Parent Role')
    child_role = Role.create!(name: 'Child Role', parent: parent_role)

    assert_equal parent_role, child_role.parent
    assert_includes parent_role.subordinate_roles, child_role
  end

  # Test for role deletion behavior
  test 'role deletion cascade' do
    parent_role = Role.create!(name: 'Parent Role')
    child_role = Role.create!(name: 'Child Role', parent: parent_role)

    parent_role.destroy
    assert_raises(ActiveRecord::RecordNotFound) { child_role.reload }
  end
end
