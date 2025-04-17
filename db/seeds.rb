require 'faker'

puts "🌱 Seeding database..."

# Institution
institution = Institution.find_or_create_by!(name: "North Carolina State University")
puts "✅ Created Institution"

# Roles
roles = ["Student", "Teaching Assistant", "Instructor", "Administrator", "Super Administrator"]
role_ids = {}

roles.each do |role_name|
  role = Role.find_or_create_by!(name: role_name)
  role_ids[role_name] = role.id
end
puts "✅ Created Roles: #{role_ids.inspect}"

# Verify Super Administrator exists
super_admin_id = role_ids["Super Administrator"]
raise "❌ Super Administrator role not found!" if super_admin_id.nil?

# Admin User
admin = User.create!(
  name: "admin",
  email: "admin@example.com",
  password: "password123",
  full_name: "Admin User",
  institution_id: institution.id,
  role_id: super_admin_id
)
puts "✅ Created Admin User"

# Instructors
instructors = 2.times.map do
  User.create!(
    name: Faker::Internet.unique.username,
    email: Faker::Internet.unique.email,
    password: "password",
    full_name: Faker::Name.name,
    institution_id: institution.id,
    role_id: role_ids["Instructor"]
  )
end
puts "✅ Created Instructors"

# Students
students = 48.times.map do
  User.create!(
    name: Faker::Internet.unique.username,
    email: Faker::Internet.unique.email,
    password: "password",
    full_name: Faker::Name.name,
    institution_id: institution.id,
    role_id: role_ids["Student"]
  )
end
puts "✅ Created Students"

# Courses
courses = instructors.map do |instructor|
  Course.create!(
    name: Faker::Educator.course_name,
    directory_path: Faker::File.dir(segment_count: 2),
    info: "Sample Course Info",
    instructor_id: instructor.id,
    institution_id: institution.id
  )
end
puts "✅ Created Courses"

# Assignments
assignments = courses.map do |course|
  Assignment.create!(
    name: Faker::Educator.subject,
    instructor_id: course.instructor_id,
    course_id: course.id,
    has_teams: true,
    has_topics: true,
    private: false
  )
end
puts "✅ Created Assignments"

# Teams
teams = assignments.flat_map do |assignment|
  8.times.map do |i|
    Team.create!(
      assignment_id: assignment.id,
      name: Faker::Team.unique.name
    )
  end
end
puts "✅ Created Teams"

# TeamsUsers
teams.each_with_index do |team, idx|
  student1 = students[(2 * idx) % students.length]
  student2 = students[(2 * idx + 1) % students.length]

  TeamsUser.create!(team_id: team.id, user_id: student1.id)
  TeamsUser.create!(team_id: team.id, user_id: student2.id)
end
puts "✅ Assigned Students to Teams"

# Participants
students.each_with_index do |student, idx|
  Participant.create!(
    user_id: student.id,
    assignment_id: assignments[idx % assignments.length].id,
    team_id: teams[idx % teams.length].id
  )
end
puts "✅ Created Participants"

# SignUpTopics
signup_topics = assignments.flat_map do |assignment|
  5.times.map do |i|
    SignUpTopic.create!(
      topic_name: Faker::Company.catch_phrase,
      assignment_id: assignment.id,
      max_choosers: 2,
      category: "Default",
      topic_identifier: Faker::Alphanumeric.alpha(number: 8).upcase,
      description: Faker::Lorem.sentence
    )
  end
end
puts "✅ Created SignUpTopics"

# SignedUpTeams
teams.each_with_index do |team, idx|
  SignedUpTeam.create!(
    sign_up_topic_id: signup_topics[idx % signup_topics.length].id,
    team_id: team.id,
    is_waitlisted: false,
    preference_priority_number: 1
  )
end
puts "✅ Created SignedUpTeams"

puts "🎉 Seeding Complete!"