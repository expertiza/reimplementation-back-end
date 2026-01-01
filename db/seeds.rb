# frozen_string_literal: true

# Create an institution
inst = Institution.find_or_create_by!(
  name: 'North Carolina State University'
)
inst_id = inst.id

# Create Roles
Role.find_or_create_by!(id: 1, name: 'Super Administrator')
Role.find_or_create_by!(id: 2, name: 'Administrator')
Role.find_or_create_by!(id: 3, name: 'Instructor')
Role.find_or_create_by!(id: 4, name: 'Teaching Assistant')
Role.find_or_create_by!(id: 5, name: 'Student')

# Create an admin user
User.find_or_create_by!(name: 'admin') do |user|
  user.email = 'admin2@example.com'
  user.password = 'password123'
  user.full_name = 'admin admin'
  user.institution_id = 1
  user.role_id = 1
end

# Check if we should generate random data
# We assume if instructors exist, we've already seeded random data
if User.where(role_id: 3).exists?
  puts "Random data already seeded (Instructors found). Skipping..."
else
  # Generate Random Users
  num_students = 48
  num_assignments = 8
  num_teams = 16
  num_courses = 2
  num_instructors = 2

  puts "creating instructors"
  instructor_user_ids = []
  num_instructors.times do
    instructor_user_ids << User.create(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",
      full_name: Faker::Name.name,
      institution_id: 1,
      role_id: 3
    ).id
  end

  puts "creating courses"
  course_ids = []
  num_courses.times do |i|
    course_ids << Course.create(
      instructor_id: instructor_user_ids[i],
      institution_id: inst_id,
      directory_path: Faker::File.dir(segment_count: 2),
      name: Faker::Company.industry,
      info: "A fake class",
      private: false
    ).id
  end

  puts "creating assignments"
  assignment_ids = []
  num_assignments.times do |i|
    assignment_ids << Assignment.create(
      name: Faker::Verb.base,
      instructor_id: instructor_user_ids[i % num_instructors],
      course_id: course_ids[i % num_courses],
      has_teams: true,
      private: false
    ).id
  end

  puts "creating teams"
  team_ids = []
  num_teams.times do |i|
    team_ids << AssignmentTeam.create(
      name: "Team #{i + 1}",
      parent_id: assignment_ids[i % num_assignments]
    ).id
  end

  puts "creating students"
  student_user_ids = []
  num_students.times do
    student_user_ids << User.create(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",
      full_name: Faker::Name.name,
      institution_id: 1,
      role_id: 5,
      parent_id: [nil, *instructor_user_ids].sample
    ).id
  end

  puts "assigning students to teams"
  teams_users_ids = []
  # num_students.times do |i|
  #  teams_users_ids << TeamsUser.create(
  #    team_id: team_ids[i%num_teams],
  #    user_id: student_user_ids[i]
  #  ).id
  # end

  num_students.times do |i|
    puts "Creating TeamsUser with team_id: #{team_ids[i % num_teams]}, user_id: #{student_user_ids[i]}"
    teams_user = TeamsUser.create(
      team_id: team_ids[i % num_teams],
      user_id: student_user_ids[i]
    )
    if teams_user.persisted?
      teams_users_ids << teams_user.id
      puts "Created TeamsUser with ID: #{teams_user.id}"
    else
      puts "Failed to create TeamsUser: #{teams_user.errors.full_messages.join(', ')}"
    end
  end

  puts "assigning participant to students, teams, courses, and assignments"
  participant_ids = []
  num_students.times do |i|
    participant_ids << AssignmentParticipant.create(
      user_id: student_user_ids[i],
      parent_id: assignment_ids[i%num_assignments],
      team_id: team_ids[i%num_teams],
    ).id
  end
end

questionnaire_type_names = [
  'Review',
  'Author feedback',
  'Teammate review',
  'Survey',
  'Quiz',
  'Bookmark rating',
  'Teammate review',
  'Assignment survey',
  'Course evaluation',
  'Global survey'
]

questionnaire_types = {}
questionnaire_type_names.each do |type_name|
  questionnaire_types[type_name] = QuestionnaireType.find_or_create_by!(name: type_name)
end
puts "Created questionnaire types: #{questionnaire_types.keys.join(', ')}"

item_type_names = [
  'Section header',
  'Table header',
  'Column header',
  'Criterion',
  'Text field',
  'Text area',
  'Dropdown',
  'Multiple choice',
  'Scale',
  'Grid',
  'Checkbox',
  'Upload',
]

item_types = {}
item_type_names.each do |type_name|
  item_types[type_name] = ItemType.find_or_create_by!(name: type_name)
end
puts "Created item types: #{item_types.keys.join(', ')}"
