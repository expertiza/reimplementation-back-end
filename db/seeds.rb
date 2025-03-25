begin
  puts "Starting database seeding..."

  # Ensure an institution exists
  inst = Institution.find_or_create_by!(name: 'North Carolina State University')
  inst_id = inst.id
  puts "Institution created with ID: #{inst_id}"

  # Ensure roles exist
  admin_role = Role.find_or_create_by!(id: 1, name: "Admin")
  instructor_role = Role.find_or_create_by!(id: 3, name: "Instructor")
  student_role = Role.find_or_create_by!(id: 5, name: "Student")
  puts "Roles ensured: Admin (#{admin_role.id}), Instructor (#{instructor_role.id}), Student (#{student_role.id})"

  # Create an admin user
  admin_user = User.create!(
    name: 'admin',
    email: 'admin2@example.com',
    password: 'password123',  # Rails will automatically hash this
    full_name: 'admin admin',
    institution_id: inst_id,
    role_id: admin_role.id
  )
  puts "Admin user created with ID: #{admin_user.id}"

  # Generate Random Users
  num_students = 48
  num_assignments = 8
  num_teams = 16
  num_courses = 2
  num_instructors = 2

  puts "Creating instructors..."
  instructor_user_ids = []
  num_instructors.times do
    instructor = User.create!(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",  # Rails will hash the password
      full_name: Faker::Name.name,
      institution_id: inst_id,
      role_id: instructor_role.id
    )
    instructor_user_ids << instructor.id
    puts "Created Instructor ID: #{instructor.id}"
  end

  puts "Creating courses..."
  course_ids = []
  num_courses.times do |i|
    course = Course.create!(
      instructor_id: instructor_user_ids[i],
      institution_id: inst_id,
      directory_path: Faker::File.dir(segment_count: 2),
      name: Faker::Company.industry,
      info: "A fake class",
      private: false
    )
    course_ids << course.id
    puts "Created Course ID: #{course.id}"
  end

  puts "Creating assignments..."
  assignment_ids = []
  num_assignments.times do |i|
    assignment = Assignment.create!(
      name: Faker::Verb.base,
      instructor_id: instructor_user_ids[i % num_instructors],
      course_id: course_ids[i % num_courses],
      has_teams: true,
      private: false
    )
    assignment_ids << assignment.id
    puts "Created Assignment ID: #{assignment.id}"
  end

  puts "Creating teams..."
  team_ids = []
  num_teams.times do |i|
    team = Team.create!(
      assignment_id: assignment_ids[i % num_assignments]
    )
    team_ids << team.id
    puts "Created Team ID: #{team.id}"
  end

  puts "Creating students..."
  student_user_ids = []
  num_students.times do
    student = User.create!(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",  # Rails will hash the password
      full_name: Faker::Name.name,
      institution_id: inst_id,
      role_id: student_role.id
    )
    student_user_ids << student.id
    puts "Created Student ID: #{student.id}"
  end

  puts "Assigning students to teams..."
  teams_users_ids = []
  num_students.times do |i|
    team_id = team_ids[i % num_teams]
    user_id = student_user_ids[i]

    puts "Creating TeamsUser with team_id: #{team_id}, user_id: #{user_id}"
    teams_user = TeamsUser.create!(
      team_id: team_id,
      user_id: user_id
    )

    teams_users_ids << teams_user.id
    puts "Created TeamsUser with ID: #{teams_user.id}"
  end

  puts "Assigning participants to students, teams, courses, and assignments..."
  participant_ids = []
  num_students.times do |i|
    user_id = student_user_ids[i]
    assignment_id = assignment_ids[i % num_assignments]
    team_id = team_ids[i % num_teams]

    participant = Participant.create!(
      user_id: user_id,
      assignment_id: assignment_id,
      team_id: team_id
    )
    participant_ids << participant.id
    puts "Created Participant ID: #{participant.id}"
  end

  puts "Database seeding complete! ✅"

rescue ActiveRecord::RecordInvalid => e
  puts "❌ Seeding failed: #{e.message}"
end