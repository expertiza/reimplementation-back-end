# frozen_string_literal: true

begin
    #Create an instritution
    inst_id = Institution.create!(
      name: 'North Carolina State University',
    ).id

    roles = {}

    roles[:super_admin] = Role.find_or_create_by!(name: "Super Administrator", parent_id: nil)

    roles[:admin] = Role.find_or_create_by!(name: "Administrator", parent_id: roles[:super_admin].id)

    roles[:instructor] = Role.find_or_create_by!(name: "Instructor", parent_id: roles[:admin].id)

    roles[:ta] = Role.find_or_create_by!(name: "Teaching Assistant", parent_id: roles[:instructor].id)

    roles[:student] = Role.find_or_create_by!(name: "Student", parent_id: roles[:ta].id)

    puts "reached here"
    # Create an admin user
    User.create!(
      name: 'admin',
      email: 'admin2@example.com',
      password: 'password123',
      full_name: 'admin admin',
      institution_id: 1,
      role_id: 1
    )

    # Create a test student user for easy testing
    test_student = User.create!(
      name: 'teststudent',
      email: 'student@test.com',
      password: 'password123',
      full_name: 'Test Student',
      institution_id: 1,
      role_id: 5
    )
    puts "Created test student: #{test_student.email} with password: password123"
    

    #Generate Random Users
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
        role_id: 3,
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
        instructor_id: instructor_user_ids[i%num_instructors],
        course_id: course_ids[i%num_courses],
        has_teams: true,
        private: false
      ).id
    end


    puts "creating teams"
    team_ids = []
    num_teams.times do |i|
      team_ids << AssignmentTeam.create(
        name: "Team #{i + 1}",
        parent_id: assignment_ids[i%num_assignments]
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
      ).id
    end

    puts "assigning students to teams"
    teams_users_ids = []
    #num_students.times do |i|
    #  teams_users_ids << TeamsUser.create(
    #    team_id: team_ids[i%num_teams],
    #    user_id: student_user_ids[i]
    #  ).id
    #end

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
        team_id: team_ids[i%num_teams]
      ).id
    end

    puts "creating project topics for testing"
    if assignment_ids.any?
      # Generate random topics for each assignment
      assignment_ids.each do |assignment_id|
        num_topics = rand(3..6)
        
        num_topics.times do |i|
          topic_num = rand(1000..9999)
          ProjectTopic.create!(
            topic_identifier: "E#{topic_num}",
            topic_name: "Topic #{SecureRandom.hex(4)}",
            category: "Category-#{SecureRandom.hex(3)}",
            max_choosers: rand(2..5),
            description: "Description for topic #{SecureRandom.hex(6)}",
            link: "https://github.com/",
            assignment_id: assignment_id
          )
        end
        puts "Created #{num_topics} topics for assignment #{assignment_id}"
      end
    end








rescue ActiveRecord::RecordInvalid => e
    puts e.message
    puts 'The db has already been seeded'
end
