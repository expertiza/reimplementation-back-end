# db/seeds_multi_round.rb

# 1. Create Assignment
assignment = Assignment.find_or_create_by!(name: "Multi-Round Assignment") do |a|
  a.directory_path = "multi_round_assignment"
  a.submitter_count = 0
  a.course_id = 1
  a.instructor_id = 1
  a.rounds_of_reviews = 2
end

# 2. Create Questionnaires for Round 1 and Round 2
q1 = Questionnaire.find_or_create_by!(name: "Round 1 Rubric") do |q|
  q.instructor_id = 1
  q.private = false
  q.min_question_score = 0
  q.max_question_score = 5
  q.questionnaire_type = "ReviewQuestionnaire"
end

q2 = Questionnaire.find_or_create_by!(name: "Round 2 Rubric") do |q|
  q.instructor_id = 1
  q.private = false
  q.min_question_score = 0
  q.max_question_score = 5
  q.questionnaire_type = "ReviewQuestionnaire"
end

# 3. Create Questions
question1 = Criterion.find_or_create_by!(txt: "Round 1 Question", questionnaire_id: q1.id) do |q|
  q.weight = 1
  q.seq = 1
  q.question_type = "Criterion"
  q.break_before = true
  q.size = "50,3"
end

question2 = Criterion.find_or_create_by!(txt: "Round 2 Question", questionnaire_id: q2.id) do |q|
  q.weight = 1
  q.seq = 1
  q.question_type = "Criterion"
  q.break_before = true
  q.size = "50,3"
end

# 4. Link Questionnaires to Assignment
AssignmentQuestionnaire.find_or_create_by!(assignment_id: assignment.id, questionnaire_id: q1.id) do |aq|
  aq.notification_limit = 15
  aq.used_in_round = 1
end

AssignmentQuestionnaire.find_or_create_by!(assignment_id: assignment.id, questionnaire_id: q2.id) do |aq|
  aq.notification_limit = 15
  aq.used_in_round = 2
end

# 5. Create Participants (Reviewer)
reviewer_user = User.find_or_create_by!(name: "reviewer5") do |u|
  u.full_name = "Reviewer 5"
  u.email = "reviewer5@example.com"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = Role.find_by(name: 'Student')
  u.institution = Institution.first
end

reviewer = Participant.find_or_create_by!(user_id: reviewer_user.id, parent_id: assignment.id) do |p|
  p.type = 'AssignmentParticipant'
  p.handle = "multi_handle"
end

# 6. Create Team (Reviewee)
team = Team.find_or_create_by!(name: "Multi-Round Team", parent_id: assignment.id) do |t|
  t.type = 'AssignmentTeam'
end

# 7. Create Response Map
map = ReviewResponseMap.find_or_create_by!(reviewed_object_id: assignment.id, reviewer_id: reviewer.id, reviewee_id: team.id)

# 8. Create Responses for Round 1 and Round 2

# Round 1 Response
resp1 = Response.create!(map_id: map.id, is_submitted: true, additional_comment: "Round 1 Feedback")
Answer.create!(response_id: resp1.id, question_id: question1.id, answer: 4, comments: "Good start")

# Round 2 Response
resp2 = Response.create!(map_id: map.id, is_submitted: true, additional_comment: "Round 2 Feedback")
Answer.create!(response_id: resp2.id, question_id: question2.id, answer: 5, comments: "Excellent improvements")

puts "Seeded Multi-Round Assignment ID: #{assignment.id}"
