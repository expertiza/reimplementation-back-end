# frozen_string_literal: true

begin
  # Create an instritution
  inst_id = Institution.create!(
    name: 'North Carolina State University'
  ).id

  Role.create!(id: 1, name: 'Super Administrator')
  Role.create!(id: 2, name: 'Administrator')
  Role.create!(id: 3, name: 'Instructor')
  Role.create!(id: 4, name: 'Teaching Assistant')
  Role.create!(id: 5, name: 'Student')

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
    participant = AssignmentParticipant.create(
      user_id: student_user_ids[i],
      parent_id: assignment_ids[i%num_assignments],
      team_id: team_ids[i%num_teams],
      handle: Faker::Internet.unique.username,
    )
    if participant.persisted?
      puts "Created AssignmentParticipant with ID: #{participant.id}"
      participant_ids << participant.id
      TeamsParticipant.create!(
        team_id: team_ids[i%num_teams],
        participant_id: participant.id,
        user_id: student_user_ids[i]
      )
    else
      puts "Failed to create AssignmentParticipant: #{participant.errors.full_messages.join(', ')}"
    end
  end

  puts "creating submission records (hyperlinks and files)"
  hyperlink_samples = [
    "https://github.com/ncsu-csc/project-repo",
    "https://github.com/ncsu-csc/demo-app",
    "https://youtu.be/dQw4w9WgXcQ",
    "https://docs.google.com/presentation/d/example",
    "https://github.com/student-team/final-project"
  ]

  file_samples = [
    { name: "report.pdf", url: "https://www.w3.org/WAI/UR/terms/media/sample.pdf", type: "pdf" },
    { name: "slides.pptx", url: "https://file-examples.com/storage/sample.pptx", type: "pptx" },
    { name: "readme.md", url: "https://raw.githubusercontent.com/github/docs/main/README.md", type: "md" }
  ]

  num_teams.times do |i|
    team = AssignmentTeam.find(team_ids[i])
    participant = AssignmentParticipant.find_by(team_id: team.id)
    next unless participant

    assignment_id = team.parent_id

    # Add 1-2 hyperlinks per team
    rand(1..2).times do |j|
      url = hyperlink_samples[(i + j) % hyperlink_samples.length]
      # Store on the team's hyperlinks list
      team.submit_hyperlink(url) rescue nil
      # Create audit record
      SubmissionRecord.create(
        record_type: 'hyperlink',
        content: url,
        operation: 'Submit Hyperlink',
        team_id: team.id,
        user: participant.user&.name || "student#{i}",
        assignment_id: assignment_id,
        created_at: Faker::Time.backward(days: 14)
      )
    end

    file = file_samples[i % file_samples.length]
    SubmissionRecord.create(
      record_type: 'file',
      content: file[:url],        # store real URL instead of local path
      operation: 'Submit File',
      team_id: team.id,
      user: participant.user&.name || "student#{i}",
      assignment_id: team.parent_id,
      created_at: Faker::Time.backward(days: 7)
    )
  end

rescue ActiveRecord::RecordInvalid => e
  puts e, 'The db has already been seeded'
end
