# db/seeds.rb

# Check or create the institution
institution = Institution.find_or_create_by!(id: 1) do |inst|
  inst.name = 'North Carolina State University'
end

# Create users for each role type
User.find_or_create_by!(email: 'student@ncsu.edu') do |student|
  student.name = 'student'
  student.password = 'password123'
  student.full_name = 'student student'
  student.institution = institution
  student.role = Role.find_by(name: 'Student')
end

User.find_or_create_by!(email: 'ta@ncsu.edu') do |ta|
  ta.name = 'ta'
  ta.password = 'password123'
  ta.full_name = 'ta ta'
  ta.institution = institution
  ta.role = Role.find_by(name: 'Teaching Assistant')
end

User.find_or_create_by!(email: 'instructor@ncsu.edu') do |instructor|
  instructor.name = 'instructor'
  instructor.password = 'password123'
  instructor.full_name = 'instructor instructor'
  instructor.institution = institution
  instructor.role = Role.find_by(name: 'Instructor')
end

User.find_or_create_by!(email: 'admin@ncsu.edu') do |admin|
  admin.name = 'admin'
  admin.password = 'password123'
  admin.full_name = 'admin admin'
  admin.institution = institution
  admin.role = Role.find_by(name: 'Administrator')
end

User.find_or_create_by!(email: 'super_admin@ncsu.edu') do |super_admin|
  super_admin.name = 'super_admin'
  super_admin.password = 'password123'
  super_admin.full_name = 'super_admin super_admin'
  super_admin.institution = institution
  super_admin.role = Role.find_by(name: 'Super Administrator')
end
