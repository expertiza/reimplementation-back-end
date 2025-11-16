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

    # puts "assigning students to teams"
    # teams_users_ids = []
    # num_students.times do |i|
    #  teams_users_ids << TeamsUser.create(
    #    team_id: team_ids[i%num_teams],
    #    user_id: student_user_ids[i]
    #  ).id
    # end

    puts "assigning participant to students, teams, courses, and assignments"
    participant_ids = []
    teams_participant_ids = []
    (num_students/2).times do |i|
      user_id = student_user_ids[i]
      handle = User.find(user_id).handle
      participant = Participant.create(
        user_id: user_id,
        parent_id: 1,
        team_id: team_ids[i%num_teams],
        type: 'AssignmentParticipant',
        handle: handle
      )

      if participant.persisted?
        participant_ids << participant.id
        puts "Created assignment participant #{participant.id}"

        teams_participant = TeamsParticipant.create(
          participant_id: participant.id,
          team_id: participant.team_id,
          user_id: participant.user_id          
        )
        if teams_participant.persisted?
          teams_participant_ids << teams_participant.id
          puts "Created TeamsParticipant ID: #{teams_participant.id}"
        else
          puts "Failed to create TeamsParticipant: #{teams_participant.errors.full_messages.join(', ')}"
        end        
      else
        puts "Failed to create assignment participant: #{participant.errors.full_messages.join(', ')}"
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








rescue ActiveRecord::RecordInvalid => e
  puts "Seeding failed or the db is already seeded: #{e.message}"
end