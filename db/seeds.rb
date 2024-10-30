# db/seeds.rb

# Check or create the institution
institution = Institution.find_or_create_by!(id: 1) do |inst|
  inst.name = 'North Carolina State University'
end

# Keep an admin for testing purposes
User.find_or_create_by!(email: 'admin@ncsu.edu') do |admin|
  admin.name = 'admin'
  admin.password = 'password123'
  admin.full_name = 'admin admin'
  admin.institution = institution
  admin.role = Role.find_by(name: 'Administrator')
end
