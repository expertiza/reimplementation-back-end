require 'faker'

puts "🌱 Seeding database..."

ActiveRecord::Base.transaction do
  # Destroy dependent data first to avoid foreign key constraint errors
  CalibrationMapping.delete_all
  ReviewResponseMap.delete_all
  ResponseMap.delete_all
  ReviewMapping.delete_all
  SignedUpTeam.delete_all
  SignUpTopic.delete_all
  Participant.delete_all
  TeamsUser.delete_all
  Team.delete_all
  Assignment.delete_all
  Course.delete_all
  Questionnaire.delete_all
  User.delete_all
  Role.delete_all
  Institution.delete_all
end

puts"✅ Cleanup complete"

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
admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "admin"
  user.password = "password123"
  user.full_name = "Admin User"
  user.institution_id = institution.id
  user.role_id = super_admin_id
end
puts "✅ Created Admin User"

# Instructors
instructors = 2.times.map do
  loop do
    name = Faker::Internet.unique.username
    break User.find_or_create_by!(name: name) do |user|
      user.email = Faker::Internet.unique.email
      user.password = "password"
      user.full_name = Faker::Name.name
      user.institution_id = institution.id
      user.role_id = role_ids["Instructor"]
    end
  end
end
puts "✅ Created Instructors"

# Students
students = 48.times.map do
  loop do
    name = Faker::Internet.unique.username
    break User.find_or_create_by!(name: name) do |user|
      user.email = Faker::Internet.unique.email
      user.password = "password"
      user.full_name = Faker::Name.name
      user.institution_id = institution.id
      user.role_id = role_ids["Student"]
    end
  end
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

# Create specific test users for review mappings
puts "📝 Creating specific test users..."
test_users = {
  instructor: User.find_or_create_by!(email: "instructor@example.com") do |user|
    user.name = "test_instructor"
    user.password = "password"
    user.full_name = "Test Instructor"
    user.institution_id = institution.id
    user.role_id = role_ids["Instructor"]
  end,
  ta: User.find_or_create_by!(email: "ta@example.com") do |user|
    user.name = "test_ta"
    user.password = "password"
    user.full_name = "Test TA"
    user.institution_id = institution.id
    user.role_id = role_ids["Teaching Assistant"]
  end,
  student1: User.find_or_create_by!(email: "student1@example.com") do |user|
    user.name = "student1"
    user.password = "password"
    user.full_name = "Test Student 1"
    user.institution_id = institution.id
    user.role_id = role_ids["Student"]
  end,
  student2: User.find_or_create_by!(email: "student2@example.com") do |user|
    user.name = "student2"
    user.password = "password"
    user.full_name = "Test Student 2"
    user.institution_id = institution.id
    user.role_id = role_ids["Student"]
  end,
  student3: User.find_or_create_by!(email: "student3@example.com") do |user|
    user.name = "student3"
    user.password = "password"
    user.full_name = "Test Student 3"
    user.institution_id = institution.id
    user.role_id = role_ids["Student"]
  end
}
puts "✅ Created specific test users"

# 1. Test data for add_reviewer
add_reviewer_assignment = Assignment.create!(
  name: "Add Reviewer Test",
  instructor_id: test_users[:instructor].id,
  course_id: courses.first.id,
  has_teams: true,
  has_topics: true,
  private: false
)

# Create teams for add_reviewer
add_reviewer_teams = 2.times.map do
  Team.create!(assignment_id: add_reviewer_assignment.id)
end

# Assign students to teams
TeamsUser.create!(team_id: add_reviewer_teams[0].id, user_id: test_users[:student1].id)
TeamsUser.create!(team_id: add_reviewer_teams[0].id, user_id: test_users[:student2].id)

# Create participants
Participant.create!(user_id: test_users[:student1].id, assignment_id: add_reviewer_assignment.id, team_id: add_reviewer_teams[0].id)
Participant.create!(user_id: test_users[:student2].id, assignment_id: add_reviewer_assignment.id, team_id: add_reviewer_teams[0].id)
Participant.create!(user_id: test_users[:student3].id, assignment_id: add_reviewer_assignment.id, team_id: nil)

# Create topics for add_reviewer
add_reviewer_topics = 2.times.map do |i|
  SignUpTopic.create!(
    topic_name: "Add Reviewer Topic #{i + 1}",
    assignment_id: add_reviewer_assignment.id,
    max_choosers: 2,
    category: "Default",
    topic_identifier: "ART#{i + 1}",
    description: "Test topic for add_reviewer"
  )
end

# Assign team to topic
SignedUpTeam.create!(
  sign_up_topic_id: add_reviewer_topics[0].id,
  team_id: add_reviewer_teams[0].id,
  is_waitlisted: false,
  preference_priority_number: 1
)

# 2. Test data for assign_reviewer_dynamically
dynamic_reviewer_assignment = Assignment.create!(
  name: "Dynamic Reviewer Test",
  instructor_id: test_users[:instructor].id,
  course_id: courses.first.id,
  has_teams: true,
  has_topics: true,
  private: false
)

# Create teams for dynamic reviewer
dynamic_teams = 2.times.map do
  Team.create!(assignment_id: dynamic_reviewer_assignment.id)
end

# Assign students to teams
TeamsUser.create!(team_id: dynamic_teams[0].id, user_id: test_users[:student1].id)
TeamsUser.create!(team_id: dynamic_teams[1].id, user_id: test_users[:student2].id)

# Create participants
Participant.create!(user_id: test_users[:student1].id, assignment_id: dynamic_reviewer_assignment.id, team_id: dynamic_teams[0].id)
Participant.create!(user_id: test_users[:student2].id, assignment_id: dynamic_reviewer_assignment.id, team_id: dynamic_teams[1].id)
Participant.create!(user_id: test_users[:student3].id, assignment_id: dynamic_reviewer_assignment.id, team_id: nil)

# Create topics for dynamic reviewer
dynamic_topics = 2.times.map do |i|
  SignUpTopic.create!(
    topic_name: "Dynamic Topic #{i + 1}",
    assignment_id: dynamic_reviewer_assignment.id,
    max_choosers: 2,
    category: "Default",
    topic_identifier: "DT#{i + 1}",
    description: "Test topic for dynamic reviewer"
  )
end

# 3. Test data for review_allowed and check_outstanding_reviews
review_state_assignment = Assignment.create!(
  name: "Review State Test",
  instructor_id: test_users[:instructor].id,
  course_id: courses.first.id,
  has_teams: true,
  has_topics: false,
  private: false
)

# Create teams for review state
review_state_teams = 2.times.map do
  Team.create!(assignment_id: review_state_assignment.id)
end

# Assign students to teams
TeamsUser.create!(team_id: review_state_teams[0].id, user_id: test_users[:student1].id)
TeamsUser.create!(team_id: review_state_teams[1].id, user_id: test_users[:student2].id)

# Create participants
Participant.create!(user_id: test_users[:student1].id, assignment_id: review_state_assignment.id, team_id: review_state_teams[0].id)
Participant.create!(user_id: test_users[:student2].id, assignment_id: review_state_assignment.id, team_id: review_state_teams[1].id)

# Create review mappings with different states
reviewer_participant = Participant.find_by!(user_id: test_users[:student1].id, assignment_id: review_state_assignment.id)

ReviewResponseMap.create!(
  reviewer_id: reviewer_participant.id,
  reviewee_id: review_state_teams[1].id,
  reviewed_object_id: review_state_assignment.id
)


# 4. Test data for assign_quiz_dynamically
quiz_assignment = Assignment.create!(
  name: "Quiz Assignment Test",
  instructor_id: test_users[:instructor].id,
  course_id: courses.first.id,
  has_teams: true,
  has_topics: false,
  private: false
)

# Create quiz questionnaire
quiz_questionnaire = Questionnaire.create!(
  name: "Test Quiz",
  instructor_id: test_users[:instructor].id,
  private: false,
  min_question_score: 0,
  max_question_score: 5,
  questionnaire_type: "QuizQuestionnaire"
)

# Create teams for quiz
quiz_teams = 2.times.map do
  Team.create!(assignment_id: quiz_assignment.id)
end

# Assign students to teams
TeamsUser.create!(team_id: quiz_teams[0].id, user_id: test_users[:student1].id)
TeamsUser.create!(team_id: quiz_teams[1].id, user_id: test_users[:student2].id)

# Create participants
Participant.create!(user_id: test_users[:student1].id, assignment_id: quiz_assignment.id, team_id: quiz_teams[0].id)
Participant.create!(user_id: test_users[:student2].id, assignment_id: quiz_assignment.id, team_id: quiz_teams[1].id)

# 5. Test data for start_self_review
self_review_assignment = Assignment.create!(
  name: "Self Review Test",
  instructor_id: test_users[:instructor].id,
  course_id: courses.first.id,
  has_teams: true,
  has_topics: false,
  private: false
)

# Create teams for self review
self_review_teams = 2.times.map do
  Team.create!(assignment_id: self_review_assignment.id)
end

# Assign students to teams
TeamsUser.create!(team_id: self_review_teams[0].id, user_id: test_users[:student1].id)
TeamsUser.create!(team_id: self_review_teams[1].id, user_id: test_users[:student2].id)

# Create participants
Participant.create!(user_id: test_users[:student1].id, assignment_id: self_review_assignment.id, team_id: self_review_teams[0].id)
Participant.create!(user_id: test_users[:student2].id, assignment_id: self_review_assignment.id, team_id: self_review_teams[1].id)

puts "✅ Created organized test data for all review mappings functions"

# 6. Test data for add_calibration
calibration_assignment = Assignment.create!(
  name: "Calibration Test",
  instructor_id: test_users[:instructor].id,
  course_id: courses.first.id,
  has_teams: true,
  has_topics: false,
  private: false
)

# Create teams for calibration
calibration_teams = 2.times.map do
  Team.create!(assignment_id: calibration_assignment.id)
end

# Assign students to teams
TeamsUser.create!(team_id: calibration_teams[0].id, user_id: test_users[:student1].id)
TeamsUser.create!(team_id: calibration_teams[1].id, user_id: test_users[:student2].id)

# Create participants
Participant.create!(user_id: test_users[:student1].id, assignment_id: calibration_assignment.id, team_id: calibration_teams[0].id)
Participant.create!(user_id: test_users[:student2].id, assignment_id: calibration_assignment.id, team_id: calibration_teams[1].id)

# Create calibration mappings
CalibrationMapping.create!(
  assignment_id: calibration_assignment.id,
  team_id: calibration_teams[0].id
)

puts "✅ Created test data for calibration functions"

# Create a new assignment with questionnaire
review_assignment = Assignment.create!(
  name: "Review Assignment with Questionnaire",
  instructor_id: test_users[:instructor].id,
  course_id: courses.first.id,
  has_teams: true,
  has_topics: false,
  private: false
)

questionnaire = Questionnaire.create!(
  name: "Review Questionnaire",
  instructor_id: test_users[:instructor].id,
  private: false,
  min_question_score: 0,
  max_question_score: 10,
  questionnaire_type: "ReviewQuestionnaire"
)

AssignmentQuestionnaire.create!(
  assignment_id: review_assignment.id,
  questionnaire_id: questionnaire.id,
  used_in_round: 1
)
puts "✅ Created review assignment with questionnaire (ID: #{review_assignment.id})"

puts "🎉 Seeding Complete!"