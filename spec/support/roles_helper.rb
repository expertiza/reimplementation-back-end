# spec/support/roles_helper.rb
module RolesHelper
  def create_roles_hierarchy
    # Create roles in hierarchy using the factory
    super_admin = FactoryBot.create(:role, :super_administrator)
    admin = FactoryBot.create(:role, :administrator, :with_parent, parent: super_admin)
    instructor = FactoryBot.create(:role, :instructor, :with_parent, parent: admin)
    ta = FactoryBot.create(:role, :ta, :with_parent, parent: instructor)
    student = FactoryBot.create(:role, :student, :with_parent, parent: ta)

    # Return the roles as a hash for easy access in specs
    {
      super_admin: super_admin,
      admin: admin,
      instructor: instructor,
      ta: ta,
      student: student
    }
  end
end