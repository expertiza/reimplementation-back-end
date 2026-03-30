# frozen_string_literal: true

require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  test 'validations' do
    role = Role.new(name: nil)
    assert_not role.valid?
    assert_equal ["can't be blank"], role.errors[:name]

    role.name = 'UniqueRoleValidation'
    assert role.save

    new_role = Role.new(name: 'UniqueRoleValidation')
    assert_not new_role.valid?
    assert_equal ['has already been taken'], new_role.errors[:name]
  end

  test 'instance methods' do
    super_admin = roles(:super_admin_role)
    admin = roles(:admin_role)
    instructor = roles(:instructor_role)
    ta = roles(:ta_role)
    student = roles(:student_role)

    assert super_admin.super_admin?
    assert_not admin.super_admin?

    assert super_admin.admin?
    assert admin.admin?
    assert_not instructor.admin?

    assert instructor.instructor?
    assert_not ta.instructor?

    assert ta.ta?
    assert_not student.ta?

    assert student.student?
    assert_not super_admin.student?
  end

  test 'subordinate_roles_and_self' do
    parent = roles(:parent_role)
    child1 = roles(:child_role1)
    child2 = roles(:child_role2)

    # parent should include itself + children
    expected_ids = [parent.id, child1.id, child2.id].sort
    assert_equal expected_ids, parent.subordinate_roles_and_self.sort

    # child1 should include itself only
    assert_equal [child1.id], child1.subordinate_roles_and_self
  end

  test 'all_privileges_of?' do
    super_admin = roles(:super_admin_role)
    admin = roles(:admin_role)
    instructor = roles(:instructor_role)
    ta = roles(:ta_role)
    student = roles(:student_role)

    assert super_admin.all_privileges_of?(admin)
    assert_not admin.all_privileges_of?(super_admin)

    assert admin.all_privileges_of?(instructor)
    assert_not instructor.all_privileges_of?(admin)

    assert instructor.all_privileges_of?(ta)
    assert_not ta.all_privileges_of?(instructor)

    assert ta.all_privileges_of?(student)
    assert_not student.all_privileges_of?(ta)
  end
end