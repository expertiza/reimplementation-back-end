#This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# institution = Institution.create!(
#   name: 'NC State'
# )

# db/seeds.rb

# Find or create the Institution
institution = Institution.find_or_create_by(name: 'NC State')

# Find or create the admin user
admin = User.find_or_create_by(name: 'admin') do |user|
  user.update!(
    password_digest: BCrypt::Password.create('admin'), # Hashed password
    full_name: 'Admin Admin',
    email: 'admin.admin@example.com',
    mru_directory_path: '/path/to/directory',
    email_on_review: true,
    email_on_submission: false,
    email_on_review_of_review: true,
    is_new_user: true,
    master_permission_granted: false,
    handle: 'admin123',
    persistence_token: 'token123',
    timeZonePref: 'UTC',
    copy_of_emails: false,
    etc_icons_on_homepage: true,
    locale: 1,
    role_id: 2,
    institution: institution
  )
end

# Find or create the instructor user
instructor = User.find_or_create_by(name: 'instructor') do |user|
  user.update!(
    password_digest: BCrypt::Password.create('instructor'), # Hashed password
    full_name: 'Instructor Abc',
    email: 'instructor.ins@example.com',
    mru_directory_path: '/path/to/directory',
    email_on_review: true,
    email_on_submission: false,
    email_on_review_of_review: true,
    is_new_user: true,
    master_permission_granted: false,
    handle: 'instruct',
    persistence_token: 'token123',
    timeZonePref: 'UTC',
    copy_of_emails: false,
    etc_icons_on_homepage: true,
    locale: 1,
    role_id: 3,
    institution: institution
  )
end

student1 = User.find_or_create_by(name: 'studentone') do |user|
  user.update!(
    password_digest: BCrypt::Password.create('student'), # Hashed password
    full_name: 'Student 1',
    email: 'student1@test.com',
    mru_directory_path: '/path/to/directory',
    email_on_review: true,
    email_on_submission: true,
    email_on_review_of_review: true,
    is_new_user: false,
    master_permission_granted: false,
    handle: 'handle',
    persistence_token: 'token123',
    timeZonePref: 'UTC',
    copy_of_emails: false,
    etc_icons_on_homepage: true,
    locale: 1,
    role_id: 5,
    institution: institution
  )
end

student2 = User.find_or_create_by(name: 'studenttwo') do |user|
  user.update!(
    password_digest: BCrypt::Password.create('student'), # Hashed password
    full_name: 'Student 2',
    email: 'student2@test.com',
    mru_directory_path: '/path/to/directory',
    email_on_review: true,
    email_on_submission: true,
    email_on_review_of_review: true,
    is_new_user: false,
    master_permission_granted: false,
    handle: 'handle',
    persistence_token: 'token123',
    timeZonePref: 'UTC',
    copy_of_emails: false,
    etc_icons_on_homepage: true,
    locale: 1,
    role_id: 5,
    institution: institution
  )
end

team1 = Team.find_or_create_by(id: 1)

assignment1 = Assignment.find_or_create_by(name: 'aone')
assignment2 = Assignment.find_or_create_by(name: 'atwo')

submission_record = SubmissionRecord.find_or_create_by(id: 1) do |submit|
  submit.update!(
    content: 'pdf',
    operation: 'store',
    team_id: 1,
    user: student1.name,
    assignment_id: 1
  )
end

# Find or create the course
OODD = Course.find_or_create_by(name: 'Object Oriented Design and Development') do |course|
  course.update!(
    directory_path: '/programming101',
    info: 'This is an introductory course on Design Patterns.',
    private: false,
    instructor: instructor,
    institution: institution
  )
end
