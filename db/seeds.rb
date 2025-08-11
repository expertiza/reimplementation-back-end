# db/seeds.rb
require 'faker'

# ----- Fixed Baseline Data -----
institution = Institution.find_or_create_by!(name: 'NC State')

admin = User.find_or_create_by!(name: 'admin') do |user|
  user.password_digest = BCrypt::Password.create('admin')
  user.full_name = 'Admin Admin'
  user.email = 'admin.admin@example.com'
  user.mru_directory_path = '/path/to/directory'
  user.email_on_review = true
  user.email_on_submission = false
  user.email_on_review_of_review = true
  user.is_new_user = true
  user.master_permission_granted = false
  user.handle = 'admin123'
  user.persistence_token = 'token123'
  user.timeZonePref = 'UTC'
  user.copy_of_emails = false
  user.etc_icons_on_homepage = true
  user.locale = 1
  user.role_id = 2
  user.institution_id = institution.id
end

instructor = User.find_or_create_by!(name: 'instructor') do |user|
  user.password_digest = BCrypt::Password.create('instructor')
  user.full_name = 'Instructor Abc'
  user.email = 'instructor.ins@example.com'
  user.mru_directory_path = '/path/to/directory'
  user.email_on_review = true
  user.email_on_submission = false
  user.email_on_review_of_review = true
  user.is_new_user = true
  user.master_permission_granted = false
  user.handle = 'instruct'
  user.persistence_token = 'token123'
  user.timeZonePref = 'UTC'
  user.copy_of_emails = false
  user.etc_icons_on_homepage = true
  user.locale = 1
  user.role_id = 3
  user.institution_id = institution.id
end

student1 = User.find_or_create_by!(name: 'studentone') do |user|
  user.password_digest = BCrypt::Password.create('student')
  user.full_name = 'Student 1'
  user.email = 'student1@test.com'
  user.mru_directory_path = '/path/to/directory'
  user.email_on_review = true
  user.email_on_submission = true
  user.email_on_review_of_review = true
  user.is_new_user = false
  user.master_permission_granted = false
  user.handle = 'handle'
  user.persistence_token = 'token123'
  user.timeZonePref = 'UTC'
  user.copy_of_emails = false
  user.etc_icons_on_homepage = true
  user.locale = 1
  user.role_id = 5
  user.institution_id = institution.id
end

student2 = User.find_or_create_by!(name: 'studenttwo') do |user|
  user.password_digest = BCrypt::Password.create('student')
  user.full_name = 'Student 2'
  user.email = 'student2@test.com'
  user.mru_directory_path = '/path/to/directory'
  user.email_on_review = true
  user.email_on_submission = true
  user.email_on_review_of_review = true
  user.is_new_user = false
  user.master_permission_granted = false
  user.handle = 'handle'
  user.persistence_token = 'token123'
  user.timeZonePref = 'UTC'
  user.copy_of_emails = false
  user.etc_icons_on_homepage = true
  user.locale = 1
  user.role_id = 5
  user.institution_id = institution.id
end

odd = Course.find_or_create_by!(name: 'Object Oriented Design and Development') do |course|
  course.directory_path = '/programming101'
  course.info = 'This is an introductory course on Design Patterns.'
  course.private = false
  course.instructor_id = instructor.id
  course.institution_id = institution.id
end

assignment1 = Assignment.find_or_create_by!(name: 'aone', directory_path: 'aone', instructor_id: instructor.id, course_id: odd.id)
assignment2 = Assignment.find_or_create_by!(name: 'atwo', directory_path: 'atwo', instructor_id: instructor.id, course_id: odd.id)

participant_a1s1 = Participant.find_or_create_by!(user_id: student1.id, parent_id: assignment1.id, type: 'AssignmentParticipant')
participant_a1s2 = Participant.find_or_create_by!(user_id: student2.id, parent_id: assignment1.id, type: 'AssignmentParticipant')
participant_a2s1 = Participant.find_or_create_by!(user_id: student1.id, parent_id: assignment2.id, type: 'AssignmentParticipant')
participant_a2s2 = Participant.find_or_create_by!(user_id: student2.id, parent_id: assignment2.id, type: 'AssignmentParticipant')

team1 = Team.find_or_create_by!(directory_num: 0, parent_id: assignment1.id, type: 'AssignmentTeam', name: 'Team 1', user_id: instructor.id)
team2 = Team.find_or_create_by!(directory_num: 1, parent_id: assignment2.id, type: 'AssignmentTeam', name: 'Team 2', user_id: instructor.id)

TeamsUser.find_or_create_by!(team_id: team1.id, user_id: student1.id)
TeamsUser.find_or_create_by!(team_id: team1.id, user_id: student2.id)
TeamsUser.find_or_create_by!(team_id: team2.id, user_id: student1.id)
TeamsUser.find_or_create_by!(team_id: team2.id, user_id: student2.id)

# ----- Bulk Randomized Data -----
begin
  num_students = 48
  num_assignments = 8
  num_teams = 16
  num_courses = 2
  num_instructors = 2

  puts "Creating instructors..."
  instructor_user_ids = []
  num_instructors.times do
    instructor_user_ids << User.create!(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password_digest: BCrypt::Password.create('password'),
      full_name: Faker::Name.name,
      institution_id: institution.id,
      role_id: 3
    ).id
  end

  puts "Creating courses..."
  course_ids = []
  num_courses.times do |i|
    course_ids << Course.create!(
      instructor_id: instructor_user_ids[i],
      institution_id: institution.id,
      directory_path: Faker::File.dir(segment_count: 2),
      name: Faker::Company.industry,
      info: "A fake class",
      private: false
    ).id
  end

  puts "Creating assignments..."
  assignment_ids = []
  num_assignments.times do |i|
    assignment_ids << Assignment.create!(
      name: Faker::Verb.base,
      instructor_id: instructor_user_ids[i % num_instructors],
      course_id: course_ids[i % num_courses],
      has_teams: true,
      private: false
    ).id
  end

  puts "Creating teams..."
  team_ids = []
  num_teams.times do |i|
    team_ids << Team.create!(
      parent_id: assignment_ids[i % num_assignments],
      name: Faker::Team.name,
      user_id: instructor_user_ids[i % num_instructors],
      type: 'AssignmentTeam'
    ).id
  end

  puts "Creating students..."
  student_user_ids = []
  num_students.times do
    student_user_ids << User.create!(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password_digest: BCrypt::Password.create('password'),
      full_name: Faker::Name.name,
      institution_id: institution.id,
      role_id: 5
    ).id
  end

  puts "Assigning students to teams..."
  student_user_ids.each_with_index do |student_id, i|
    TeamsUser.find_or_create_by!(
      team_id: team_ids[i % num_teams],
      user_id: student_id
    )
  end

  puts "Creating participants..."
  student_user_ids.each_with_index do |student_id, i|
    Participant.find_or_create_by!(
      user_id: student_id,
      parent_id: assignment_ids[i % num_assignments],
      team_id: team_ids[i % num_teams],
      type: 'AssignmentParticipant'
    )
  end

rescue ActiveRecord::RecordInvalid => e
  puts "Seeding skipped: #{e.message}"
end
