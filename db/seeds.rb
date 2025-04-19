require 'faker'

puts "🌱 Seeding database..."

# Institution
institution = Institution.find_or_create_by!(name: "North Carolina State University")
puts "✅ Created Institution"

# Roles
roles = ["Student", "Teaching Assistant", "Instructor", "Administrator", "Super Administrator"]
role_ids = {}

roles.each do |role_name|
  role = Role.find_or_create_by!(name: role_name)
  role_ids[role_name] = role.id
end
puts "✅ Created Roles: #{role_ids.inspect}"

# Verify Super Administrator exists
super_admin_id = role_ids["Super Administrator"]
raise "❌ Super Administrator role not found!" if super_admin_id.nil?

# Admin User
admin = User.create!(
  name: "admin",
  email: "admin@example.com",
  password: "password123",
  full_name: "Admin User",
  institution_id: institution.id,
  role_id: super_admin_id
)
puts "✅ Created Admin User"

# Instructors
instructors = 2.times.map do
  User.create!(
    name: Faker::Internet.unique.username,
    email: Faker::Internet.unique.email,
    password: "password",
    full_name: Faker::Name.name,
    institution_id: institution.id,
    role_id: role_ids["Instructor"]
  )
end
puts "✅ Created Instructors"

# Students
students = 48.times.map do
  User.create!(
    name: Faker::Internet.unique.username,
    email: Faker::Internet.unique.email,
    password: "password",
    full_name: Faker::Name.name,
    institution_id: institution.id,
    role_id: role_ids["Student"]
  )
end
puts "✅ Created Students"

# Courses
courses = instructors.map do |instructor|
  Course.create!(
    name: Faker::Educator.course_name,
    directory_path: Faker::File.dir(segment_count: 2),
    info: "Sample Course Info",
    instructor_id: instructor.id,
    institution_id: institution.id
  )
end
puts "✅ Created Courses"

# Assignments
assignments = courses.map do |course|
  Assignment.create!(
    name: Faker::Educator.subject,
    instructor_id: course.instructor_id,
    course_id: course.id,
    has_teams: true,
    has_topics: true,
    private: false
  )
end
puts "✅ Created Assignments"

# Teams
teams = assignments.flat_map do |assignment|
  8.times.map do
    Team.create!(
      assignment_id: assignment.id
    )
  end
end
puts "✅ Created Teams"

# TeamsUsers
teams.each_with_index do |team, idx|
  student1 = students[(2 * idx) % students.length]
  student2 = students[(2 * idx + 1) % students.length]

  TeamsUser.create!(team_id: team.id, user_id: student1.id)
  TeamsUser.create!(team_id: team.id, user_id: student2.id)
end
puts "✅ Assigned Students to Teams"

# Participants
students.each_with_index do |student, idx|
  Participant.create!(
    user_id: student.id,
    assignment_id: assignments[idx % assignments.length].id,
    team_id: teams[idx % teams.length].id
  )
end
puts "✅ Created Participants"

# SignUpTopics
signup_topics = assignments.flat_map do |assignment|
  5.times.map do |i|
    SignUpTopic.create!(
      topic_name: Faker::Company.catch_phrase,
      assignment_id: assignment.id,
      max_choosers: 2,
      category: "Default",
      topic_identifier: Faker::Alphanumeric.alpha(number: 8).upcase,
      description: Faker::Lorem.sentence
    )
  end
end
puts "✅ Created SignUpTopics"

# SignedUpTeams
teams.each_with_index do |team, idx|
  SignedUpTeam.create!(
    sign_up_topic_id: signup_topics[idx % signup_topics.length].id,
    team_id: team.id,
    is_waitlisted: false,
    preference_priority_number: 1
  )
end
puts "✅ Created SignedUpTeams"

puts "✅ Creating Review Mappings..."

assignments.each do |assignment|
  participants = assignment.participants.to_a
  next if participants.count < 2

  reviewers = participants.sample(3)
  reviewees = participants.sample(3)

  reviewers.zip(reviewees).each do |reviewer, reviewee|
    next if reviewer.id == reviewee.id
    ResponseMap.find_or_create_by!(
      reviewed_object_id: assignment.id,
      reviewer_id: reviewer.id,
      reviewee_id: reviewee.id,
      type: "ResponseMap"
    )
  end
end

puts "✅ Created Review Mappings"

# Add a clean assignment for testing automatic_review_mapping_strategy
test_assignment = Assignment.create!(
  name: "GSoC Strategy Test",
  instructor_id: instructors.first.id,
  course_id: courses.first.id,
  has_teams: false,
  has_topics: false,
  private: false
)

# Add 10 participants to this assignment
10.times do |i|
  Participant.create!(
    user_id: students[i].id,
    assignment_id: test_assignment.id,
    team_id: nil
  )
end

puts "✅ Created test assignment with 10 participants for strategy testing"

staggered_assignment = Assignment.create!(
  name: "Staggered Mapping Test",
  instructor_id: instructors.last.id,
  course_id: courses.last.id,
  has_teams: true,
  has_topics: false,
  private: false
)

# Create 6 teams and assign each 2 students
6.times do |t|
  team = Team.create!(assignment_id: staggered_assignment.id)
  user1 = students.sample
  user2 = students.reject { |u| u == user1 }.sample

  TeamsUser.create!(team_id: team.id, user_id: user1.id)
  TeamsUser.create!(team_id: team.id, user_id: user2.id)

  Participant.create!(user_id: user1.id, assignment_id: staggered_assignment.id, team_id: team.id)
  Participant.create!(user_id: user2.id, assignment_id: staggered_assignment.id, team_id: team.id)
end

puts "✅ Created staggered mapping assignment with 6 teams"

# Assignment for testing assign_reviewers_for_team
assign_team_reviewers_assignment = Assignment.create!(
  name: "Team Reviewer Assignment Test",
  instructor_id: instructors.first.id,
  course_id: courses.first.id,
  has_teams: true,
  has_topics: false,
  private: false
)

# Create 3 reviewee teams with 2 members each
reviewee_teams = 3.times.map do
  team = Team.create!(assignment_id: assign_team_reviewers_assignment.id)
  user1, user2 = students.sample(2)

  TeamsUser.create!(team_id: team.id, user_id: user1.id)
  TeamsUser.create!(team_id: team.id, user_id: user2.id)

  Participant.create!(user_id: user1.id, assignment_id: assign_team_reviewers_assignment.id, team_id: team.id)
  Participant.create!(user_id: user2.id, assignment_id: assign_team_reviewers_assignment.id, team_id: team.id)

  team
end

# Create 5 standalone students as potential reviewers
5.times do
  reviewer = students.reject { |s| Participant.exists?(user_id: s.id, assignment_id: assign_team_reviewers_assignment.id) }.sample

  Participant.create!(
    user_id: reviewer.id,
    assignment_id: assign_team_reviewers_assignment.id,
    team_id: nil  # Not part of a team
  )
end

puts "✅ Created assignment for assign_reviewers_for_team with 3 teams and 5 reviewers"

# Assignment for testing peer_review_strategy
peer_review_assignment = Assignment.create!(
  name: "Peer Review Strategy Test",
  instructor_id: instructors.first.id,
  course_id: courses.first.id,
  has_teams: false,  # Set to true if you want to test team-based mapping
  has_topics: false,
  private: false
)

# Add 8 participants (individuals) for the peer review strategy test
8.times do |i|
  Participant.create!(
    user_id: students[i + 20].id,
    assignment_id: peer_review_assignment.id,
    team_id: nil  # No team assignment needed for individual
  )
end

puts "✅ Created peer_review_strategy test assignment with 8 participants"

puts "✅ Creating Questionnaires and linking to Assignments"

assignments.each do |assignment|
  questionnaire = Questionnaire.create!(
    name: "#{assignment.name} Review Questionnaire",
    instructor_id: assignment.instructor_id,
    min_question_score: 0,
    max_question_score: 10
  )

  AssignmentQuestionnaire.create!(
    assignment_id: assignment.id,
    questionnaire_id: questionnaire.id
  )
end

puts "✅ Created Questionnaires and linked to Assignments"

assignments.each do |assignment|
  questionnaire = assignment.questionnaires.first
  next unless questionnaire.present?

  Item.create!(
    questionnaire_id: questionnaire.id,
    question_type: 'Grade',
    txt: 'Overall grade',
    weight: 1,
    seq: 1,
    break_before: false == false,
    max_label: '10',
    min_label: '0'
  )

  Item.create!(
    questionnaire_id: questionnaire.id,
    question_type: 'Comment',
    txt: 'Feedback comments',
    weight: 0,
    seq: 2,
    break_before: false == false
  )
end

puts "✅ Created Grade and Comment Items for all Assignments"


test_assignment_id = assignments.first.id
test_participants = Participant.where(assignment_id: test_assignment_id).limit(2)

if test_participants.size == 2 && test_participants.first.id != test_participants.last.id
  reviewee = test_participants.first
  reviewer = test_participants.last

  ResponseMap.find_or_create_by!(
    reviewed_object_id: test_assignment_id,
    reviewer_id: reviewer.id,
    reviewee_id: reviewee.id,
    type: "ResponseMap"
  )

  puts "✅ Created test ResponseMap: reviewer_id=#{reviewer.id}, reviewee_id=#{reviewee.id}, assignment_id=#{test_assignment_id}"
end


puts "🎉 Seeding Complete!"