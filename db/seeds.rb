# db/seeds.rb

# Check or create the institution
institution = Institution.find_or_create_by!(id: 1) do |inst|
  inst.name = 'North Carolina State University'
end

# Check or create the role (ensure `role_id: 1` exists)
role = Role.find_or_create_by!(id: 1) do |r|
  r.name = 'Admin'
end

# Check or create the admin user
User.find_or_create_by!(email: 'admin2@example.com') do |user|
  user.name = 'admin'
  user.password = 'password123'
  user.full_name = 'admin admin'
  user.institution = institution
  user.role = role
end
