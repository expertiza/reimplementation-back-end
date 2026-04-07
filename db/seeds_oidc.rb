User.find_or_create_by!(email: "jweisz@ncsu.edu") do |user|
  user.name = "jweisz"
  user.password = "password123"
  user.full_name = "John Weisz"
  user.institution_id = 1
  user.role_id = 1
end