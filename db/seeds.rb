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
reviewer1 = User.find_or_create_by(name: 'smith') do |user|
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
reviewee1 = User.find_or_create_by(name: 'john') do |user|
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
team1 = Team.find_or_create_by(id: 1) do |team|
  team.update!(
    id: 1
  )
  end
reviewer_participant1 = Participant.find_or_create_by(user:reviewer1) do |participant|
  participant.update!(
    user:reviewer1,
    assignment:assignment1
  )
end
reviewee_participant2 = Participant.find_or_create_by(user:reviewee1) do |participant|
  participant.update!(
    user:reviewee1,
    assignment:assignment1
  )
end
questionnaire1 = Questionnaire.find_or_create_by(name: 'questionnaire 1') do |questionnaire|
  questionnaire.update!(
    id:1,
    instructor_id:instructor.id,
    max_question_score:5,
    min_question_score:0,
    name: 'questionnaire 1'
  )
end
assignment_questionnaire1 = AssignmentQuestionnaire.find_or_create_by(id:1) do |assignment_questionnaire|
  assignment_questionnaire.update!(
    id:1,
    assignment_id:assignment1.id,
    questionnaire_id:questionnaire1.id,
    notification_limit: 3
  )
end
question1 = Question.find_or_create_by(txt:'This is a question 1') do |question|
  question.update!(
    question_type:'qustion_type1',
    max_label: 'max_label1',
    min_label: 'min_label1',
    txt: 'This is a question 1',
    weight: 5,
    seq: 1.0,
    break_before: 1,
    questionnaire: questionnaire1
  )
end
question2 = Question.find_or_create_by(txt:'This is a question 2') do |question|
  question.update!(
    question_type:'qustion_type2',
    max_label: 'max_label2',
    min_label: 'min_label2',
    txt: 'This is a question 2',
    weight: 5,
    seq: 2.0,
    break_before: 2,
    questionnaire: questionnaire1
  )
end
questions = [question1, question2]
response_map1 = ResponseMap.find_or_create_by(reviewed_object_id: 1) do |review_response_map|
  review_response_map.update!(
    reviewed_object_id:1,
    reviewee:reviewee_participant2,
    reviewer:reviewer_participant1,
    assignment: assignment1,

    )
end

response1 = Response.find_or_create_by(map_id:1) do |response|
  response.update!(
    map_id: response_map1.id,
    additional_comment: 'additional comment'
  )
end
answer1 = Answer.find_or_create_by(answer:1) do |answer|
  answer.update!(
    answer:1,
    comments:'Answer1 text',
    question_id: question1.id,
    response_id: response1.id
  )
end




