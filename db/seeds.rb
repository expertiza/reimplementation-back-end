#seeds file

# This file should contain all the record creation needed to seed the database with its default values.
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

# Find or create the course
course1 = Course.find_or_create_by(name: 'Object Oriented Design and Development') do |course|
  course.update!(
    directory_path: '/programming101',
    info: 'This is an introductory course on Design Patterns.',
    private: false,
    instructor: instructor,
    institution: institution
  )
end
user1 = User.find_or_create_by(name: 'smith') do |user|
  user.update!(
    password_digest: BCrypt::Password.create('password'), # Hashed password
    full_name: 'Smith Student',
    email: 'smith.student@example.com',
    mru_directory_path: '/path/to/directory',
    email_on_review: true,
    email_on_submission: true,
    email_on_review_of_review: true,
    is_new_user: true,
    master_permission_granted: false,
    handle: 'smith123',
    persistence_token: 'token123',
    timeZonePref: 'UTC',
    copy_of_emails: false,
    etc_icons_on_homepage: true,
    locale: 1,
    role_id: 1,
    institution: institution
  )
end
user2 = User.find_or_create_by(name: 'john') do |user|
  user.update!(
    password_digest: BCrypt::Password.create('password'), # Hashed password
    full_name: 'John Student',
    email: 'john.student@example.com',
    mru_directory_path: '/path/to/directory',
    email_on_review: true,
    email_on_submission: false,
    email_on_review_of_review: true,
    is_new_user: true,
    master_permission_granted: false,
    handle: 'john123',
    persistence_token: 'token123',
    timeZonePref: 'UTC',
    copy_of_emails: false,
    etc_icons_on_homepage: true,
    locale: 1,
    role_id: 1,
    institution: institution
  )
end
assignment1 = Assignment.find_or_create_by(name: 'Test Assignment1') do |assignment|
  assignment.update!(
    id:1,
    name: 'Test Assignment1'
  )
end
team = Team.new
participant1 = Participant.find_or_create_by(id: 1) do |participant|
  participant.update!(
    id:1,
    user:user1,
    assignment:assignment1
  )
end
questionnaire1 = Questionnaire.find_or_create_by(id:1) do |questionnaire|
  questionnaire.update!(
    id:1,
    max_question_score:5
  )
end
question1 = question.find_or_create_by(id:1) do |question|
  question.new(id: 1, weight: 2, questionnaire: questionnaire1)
end
questionnaire1 = Questionnaire.find_or_create_by(id:1) do |questionnaire|
  questionnaire.update!(
    id:1,
    questions:[question1],
    max_question_score:5
  )
end

response_map1 = ResponseMap.find_or_create_by(assignment:assignment1) do |response_map|
  response_map.update!(
    assignmet:assignment1,
    reviewee:participant1,
    reviewer:participant1
  )
end

review_response_map1 = ReviewResponseMap.find_or_create_by(assignment:assignment1) do |review_response_map|
  review_response_map.update!(
    assignment: assignment1,
    reviewee: team
  )
end

response1 = Response.find_or_create_by(map_id:1) do |response|
  response.update!(
    map_id: response_map1.id,
    review_response_map: review_response_map1,
  )
end

answer1 = Answer.find_or_create_by(answer:1) do |answer|
  answer.update!(
    answer:1,
    comments:'Answer text',
    question_id: question1.id
  )
end
response2 = Response.find_or_create_by(map_id:1) do |response|
  response.update!(
    map_id: response_map1.id,
    review_response_map: review_response_map1,
    scores:[answer1],
    )
  end

