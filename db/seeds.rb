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
student1 = User.find_or_create_by(name: 'smith') do |user|
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
student2 = User.find_or_create_by(name: 'john') do |user|
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
student3 = User.find_or_create_by(name: 'matt') do |user|
  user.update!(
    password_digest: BCrypt::Password.create('password'), # Hashed password
    full_name: 'matt Student',
    email: 'matt.student@example.com',
    mru_directory_path: '/path/to/directory',
    email_on_review: true,
    email_on_submission: false,
    email_on_review_of_review: true,
    is_new_user: true,
    master_permission_granted: false,
    handle: 'matt123',
    persistence_token: 'token123',
    timeZonePref: 'UTC',
    copy_of_emails: false,
    etc_icons_on_homepage: true,
    locale: 1,
    role_id: 1,
    institution: institution
  )
end
student4 = User.find_or_create_by(name: 'david') do |user|
  user.update!(
    password_digest: BCrypt::Password.create('password'), # Hashed password
    full_name: 'david Student',
    email: 'david.student@example.com',
    mru_directory_path: '/path/to/directory',
    email_on_review: true,
    email_on_submission: false,
    email_on_review_of_review: true,
    is_new_user: true,
    master_permission_granted: false,
    handle: 'david123',
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
    id: 1,
    name:"Team1",
    parent_id: assignment1.id,
  )
end
team2 = Team.find_or_create_by(id: 2) do |team|
  team.update!(
    id: 2,
    name:'Team2',
    parent_id: assignment1.id
  )
end
teams_user1 = TeamsUser.find_or_create_by(id:1) do |teams_user|
  teams_user.update!(
    id: 1,
    team_id:team1.id,
    user_id:student1.id
  )
end
teams_user2 = TeamsUser.find_or_create_by(id:2) do |teams_user|
  teams_user.update!(
    id: 2,
    team_id:team1.id,
    user_id:student2.id
  )
end
teams_user3 = TeamsUser.find_or_create_by(id:3) do |teams_user|
  teams_user.update!(
    id: 3,
    team_id:team2.id,
    user_id:student3.id
  )
end
teams_user4 = TeamsUser.find_or_create_by(id:4) do |teams_user|
  teams_user.update!(
    id: 4,
    team_id:team2.id,
    user_id:student4.id
  )
end
sign_up_topic1 = SignUpTopic.find_or_create_by(id:1) do |sign_up_topic|
  sign_up_topic.update!(
    id:1,
    topic_name: "Team Refactoring tools",
    assignment_id:1,
    category:"Refactoring",
    topic_identifier: "TR1",
    max_choosers: 2,
  )
end
sign_up_topic2 = SignUpTopic.find_or_create_by(id:2) do |sign_up_topic|
  sign_up_topic.update!(
    id:2,
    topic_name: "Team Applying refactoring",
    assignment_id:1,
    category:"Refactoring",
    topic_identifier: "TR2",
    max_choosers: 2,
  )
end
signed_up_team1 = SignedUpTeam.find_or_create_by(id:1) do |signed_up_team|
  signed_up_team.update!(
    id:1,
    topic_id: sign_up_topic1.id,
    team_id: team1.id,
  )
end
signed_up_team2 = SignedUpTeam.find_or_create_by(id:2) do |signed_up_team|
  signed_up_team.update!(
    id:2,
    topic_id: sign_up_topic2.id,
    team_id: team2.id,
    )
end
participant1 = Participant.find_or_create_by(user:student1) do |participant|
  participant.update!(
    user:student1,
    assignment:assignment1,
    parent_id:assignment1.id
  )
end
participant2 = Participant.find_or_create_by(user:student2) do |participant|
  participant.update!(
    user:student2,
    assignment:assignment1,
    parent_id:assignment1.id
  )
end
participant3 = Participant.find_or_create_by(user:student3) do |participant|
  participant.update!(
    user:student3,
    assignment:assignment1,
    parent_id:assignment1.id
  )
end
participant4 = Participant.find_or_create_by(user:student4) do |participant|
  participant.update!(
    user:student4,
    assignment:assignment1,
    parent_id:assignment1.id
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
    question_type:'TextField',
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
    question_type:'Checkbox',
    max_label: 'max_label2',
    min_label: 'min_label2',
    txt: 'This is a question 2',
    weight: 5,
    seq: 2.0,
    break_before: 2,
    questionnaire: questionnaire1
  )
end
question3 = Question.find_or_create_by(txt:'This is a question 3') do |question|
  question.update!(
    question_type:'Criterion',
    max_label: 'max_label3',
    min_label: 'min_label3',
    txt: 'This is a question 3',
    weight: 5,
    seq: 3.0,
    break_before: 2,
    questionnaire: questionnaire1
  )
end
question4 = Question.find_or_create_by(txt:'This is a question 4') do |question|
  question.update!(
    question_type:'Dropdown',
    max_label: 'max_label4',
    min_label: 'min_label4',
    txt: 'This is a question 4',
    weight: 5,
    seq: 4.0,
    break_before: 2,
    questionnaire: questionnaire1
  )
end
question5 = Question.find_or_create_by(txt:'This is a question 5') do |question|
  question.update!(
    question_type:'TextArea',
    max_label: 'max_label5',
    min_label: 'min_label5',
    txt: 'This is a question 5',
    weight: 5,
    seq: 5.0,
    break_before: 2,
    questionnaire: questionnaire1
  )
end

questions = [question1, question2, question3,question4,question5]
response_map1 = ResponseMap.find_or_create_by(reviewer_id:participant1.id) do |review_response_map|
  review_response_map.update!(
    reviewed_object_id:assignment1.id,
    reviewer_id:participant1.id,
    reviewee_id:team2.id,
    type: 'ReviewResponseMap'
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
answer2 = Answer.find_or_create_by(answer:2) do |answer|
  answer.update!(
    answer:2,
    comments:'Answer2 text',
    question_id: question2.id,
    response_id: response1.id
  )
end




