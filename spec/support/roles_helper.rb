module RolesHelper
  def create_roles_hierarchy
    # Ensure roles exist without duplication
    super_admin = Role.find_or_create_by!(name: 'Super Administrator') do |role|
      role.parent_id = nil
    end

    admin = Role.find_or_create_by!(name: 'Administrator') do |role|
      role.parent = super_admin
    end

    instructor = Role.find_or_create_by!(name: 'Instructor') do |role|
      role.parent = admin
    end

    ta = Role.find_or_create_by!(name: 'Teaching Assistant') do |role|
      role.parent = instructor
    end

    student = Role.find_or_create_by!(name: 'Student') do |role|
      role.parent = ta
    end

    {
      super_admin: super_admin,
      admin: admin,
      instructor: instructor,
      ta: ta,
      student: student
    }
  end
end
