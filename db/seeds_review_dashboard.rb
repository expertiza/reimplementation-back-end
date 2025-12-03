# Find or create an assignment
assignment = Assignment.first || Assignment.create!(name: "Test Assignment", directory_path: "test_assignment", submitter_count: 0, course_id: 1, instructor_id: 1)

# Create a Questionnaire
questionnaire = Questionnaire.find_or_create_by!(name: "Test Questionnaire") do |q|
  q.instructor_id = 1
  q.private = false
  q.min_question_score = 0
  q.max_question_score = 5
  q.questionnaire_type = "ReviewQuestionnaire"
end

# Create a Criterion (Question)
question = Criterion.find_or_create_by!(txt: "Rate the work", questionnaire_id: questionnaire.id) do |q|
  q.weight = 1
  q.seq = 1
  q.question_type = "Criterion"
  q.break_before = true
  q.size = "50,3" # Required by validation
end

# Link Assignment and Questionnaire
AssignmentQuestionnaire.find_or_create_by!(assignment_id: assignment.id, questionnaire_id: questionnaire.id) do |aq|
  aq.notification_limit = 15
end

# Create participants (Reviewers)
reviewers = []
4.times do |i|
  user = User.find_or_create_by!(name: "reviewer#{i+1}") do |u|
    u.full_name = "Reviewer #{i+1}"
    u.email = "reviewer#{i+1}@example.com"
    u.password = "password"
    u.password_confirmation = "password"
    u.role = Role.find_by(name: 'Student')
    u.institution = Institution.first
  end
  
  # Check if participant already exists
  participant = Participant.find_by(user_id: user.id, parent_id: assignment.id)
  unless participant
    participant = Participant.create!(user: user, parent_id: assignment.id, type: 'AssignmentParticipant', handle: "handle#{i+1}")
  end
  reviewers << participant
end

# Create teams (Reviewees)
teams = []
2.times do |i|
  team = Team.find_or_create_by!(name: "Team #{i+1}", parent_id: assignment.id) do |t|
    t.type = 'AssignmentTeam'
  end
  teams << team
end

# Create ReviewResponseMaps and Responses

# Case 1: Completed review with grade (Brown)
map1 = ReviewResponseMap.find_or_create_by!(reviewed_object_id: assignment.id, reviewer_id: reviewers[0].id, reviewee_id: teams[0].id)
map1.update!(reviewer_grade: 90, reviewer_comment: "Good job")
resp1 = Response.find_or_create_by!(map_id: map1.id) do |r|
  r.is_submitted = true
  r.additional_comment = "This is a great submission with lots of details."
end
Answer.create!(response_id: resp1.id, question_id: question.id, answer: 5, comments: "Excellent") unless Answer.exists?(response_id: resp1.id, question_id: question.id)


# Case 2: Completed review, no grade (Blue)
map2 = ReviewResponseMap.find_or_create_by!(reviewed_object_id: assignment.id, reviewer_id: reviewers[1].id, reviewee_id: teams[0].id)
resp2 = Response.find_or_create_by!(map_id: map2.id) do |r|
  r.is_submitted = true
  r.additional_comment = "Good work but needs improvement."
end
Answer.create!(response_id: resp2.id, question_id: question.id, answer: 3, comments: "Average") unless Answer.exists?(response_id: resp2.id, question_id: question.id)

# Case 3: Not completed (Red)
map3 = ReviewResponseMap.find_or_create_by!(reviewed_object_id: assignment.id, reviewer_id: reviewers[2].id, reviewee_id: teams[0].id)
# No response or not submitted
Response.find_or_create_by!(map_id: map3.id) do |r|
  r.is_submitted = false
end

# Case 4: No review (Purple)
ReviewResponseMap.find_or_create_by!(reviewed_object_id: assignment.id, reviewer_id: reviewers[3].id, reviewee_id: teams[1].id)
# No response object created

puts "Seeded review data for Assignment ID: #{assignment.id}"
