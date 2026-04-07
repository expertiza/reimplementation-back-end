# For conenience, will drop on final PR
User.find_or_create_by!(email: "jweisz@ncsu.edu") do |user|
  user.name = "jweisz"
  user.password = "password123"
  user.full_name = "John Weisz"
  user.institution_id = 1
  user.role_id = 1
end

# For conenience, will drop on final PR
User.find_or_create_by!(email: "jvargas6@ncsu.edu") do |user|
  user.name = "jvargas6"
  user.password = "password123"
  user.full_name = "Jose Vargas"
  user.institution_id = 1
  user.role_id = 1
end

# For conenience, will drop on final PR
User.find_or_create_by!(email: "jcmonseu@ncsu.edu") do |user|
  user.name = "jcmonseu"
  user.password = "password123"
  user.full_name = "Jared Monseur"
  user.institution_id = 1
  user.role_id = 1
end
