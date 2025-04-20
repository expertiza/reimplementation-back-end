begin
  # Create an instritution
  inst_id = Institution.create!(
    name: 'North Carolina State University'
  ).id

  # Create an admin user
  User.create!(
    name: 'admin',
    email: 'admin2@example.com',
    password: 'password123',
    full_name: 'admin admin',
    institution_id: 1,
    role_id: 1
  )

  # Generate Random Users
  num_students = 4
  num_assignments = 8
  num_teams = 16
  num_courses = 2
  num_instructors = 2

  # Generate Random Instructors
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

  # Generate Random Courses
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

  # Generate Specific Assignments names
  puts "Creating assignments with specific names"
  assignment_names = [
    "Program 1",
    "Program 3",
    "Program 4",
    "Program 5",
    "OSS Program 1",
    "OSS Program 2",
    "Program 6",
    "Program 7"
  ]

  # Generate Random Assignments
  puts "creating assignments"
  assignment_ids = []
  num_assignments.times do |i|
    assignment = Assignment.create(
      name: assignment_names[i],
      instructor_id: instructor_user_ids[i % num_instructors],
      course_id: course_ids[i % num_courses],
      has_teams: true,
      private: false
    )

    assignment_ids << assignment.id

    # Create DueDates for the assignment for StudentTask
    puts "Creating due_dates for assignment #{assignment.name}"
    [
      2.days.from_now,
      3.days.from_now,
      4.days.from_now,
      2.days.ago,
      3.days.ago
    ].each do |due_at|
      DueDate.create!(
        parent: assignment,
        due_at:,
        submission_allowed_id: 3,
        review_allowed_id: 3,
        deadline_type_id: 3
      )
    end
  end

  # Generate Random Teams
  puts "creating teams"
  team_ids = []
  num_teams.times do |i|
    team_ids << Team.create(
      assignment_id: assignment_ids[i % num_assignments]
    ).id
  end

  # Generate Some Students
  puts "creating students"
  student_user_ids = []
  # num_students.times do
  #   student_user_ids << User.create(
  #     name: Faker::Internet.unique.username,
  #     email: Faker::Internet.unique.email,
  #     password: "password",
  #     full_name: Faker::Name.name,
  #     institution_id: 1,
  #     role_id: 5,
  #   ).id
  # end
  #
  # Create first student with specific name "niki"
  student_user_ids << User.create!(
    name: "niki",
    email: "niki@example.com",
    password: "password",
    full_name: "Niki Jones",
    institution_id: 1,
    role_id: 5
  ).id

  # Create remaining (num_students - 1) students with Faker
  (num_students - 1).times do
    student_user_ids << User.create(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",
      full_name: Faker::Name.name,
      institution_id: 1,
      role_id: 5
    ).id
  end

  # Assign Students to Teams
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

  puts "assigning participants to all students for all assignments"
  participant_ids = []
  # Array of possible stages
  stages = ["Not started", "In progress", "Submitted", "Reviewed", "Finished"]
  student_user_ids.each do |student_id|
    assignment_ids.each do |assignment_id|
      team_id = team_ids.sample # randomly assign a team for the assignment
      participant = Participant.create(
        user_id: student_id,
        stage_deadline: Date.today + rand(1..10).days,
        topic: "Topic #{rand(1..5)}",
        permission_granted: true,
        current_stage: stages.sample,
        assignment_id:,
        team_id:
      )
      if participant.persisted?
        participant_ids << participant.id
      else
        puts "Failed to create Participant: #{participant.errors.full_messages.join(', ')}"
      end
    end
  end
rescue ActiveRecord::RecordInvalid => e
  puts 'The db has already been seeded'
end
