# frozen_string_literal: true

# Idempotent seeds: safe to run any number of times (`rake db:seed`).
# Every record is looked up by a stable key and only created if it is missing, so existing
# data is left alone and anything newly added to this file gets created on the next run.
# When adding seeds, follow the same pattern: `find_or_create_by!(<stable key>) { |r| <other attrs> }`.

# Institution
inst_id = Institution.find_or_create_by!(name: 'North Carolina State University').id

# Roles (IDs must match the Role constants)
Role.find_or_create_by!(id: 1, name: 'Student')
Role.find_or_create_by!(id: 2, name: 'Teaching Assistant')
Role.find_or_create_by!(id: 3, name: 'Instructor')
Role.find_or_create_by!(id: 4, name: 'Administrator')
Role.find_or_create_by!(id: 5, name: 'Super Administrator')

# Admin user
User.find_or_create_by!(name: 'admin') do |u|
  u.email = 'admin2@example.com'
  u.password = 'password123'
  u.full_name = 'admin admin'
  u.institution_id = inst_id
  u.role_id = 5
end

# Sample data
num_students = 48
num_assignments = 8
num_teams = 16
num_courses = 2
num_instructors = 2

puts "creating instructors"
instructor_user_ids = (1..num_instructors).map do |i|
  User.find_or_create_by!(name: "instructor#{i}") do |u|
    u.email = "instructor#{i}@example.com"
    u.password = "password"
    u.full_name = Faker::Name.name
    u.institution_id = inst_id
    u.role_id = 3
  end.id
end

puts "creating courses"
course_ids = (0...num_courses).map do |i|
  Course.find_or_create_by!(name: "Course #{i + 1}", instructor_id: instructor_user_ids[i]) do |c|
    c.institution_id = inst_id
    c.directory_path = "course_#{i + 1}"
    c.info = "A fake class"
    c.private = false
  end.id
end

puts "creating assignments"
assignment_ids = (0...num_assignments).map do |i|
  Assignment.find_or_create_by!(name: "Assignment #{i + 1}", course_id: course_ids[i % num_courses]) do |a|
    a.instructor_id = instructor_user_ids[i % num_instructors]
    a.has_teams = true
    a.private = false
  end.id
end

puts "creating teams"
team_ids = (0...num_teams).map do |i|
  AssignmentTeam.find_or_create_by!(name: "Team #{i + 1}", parent_id: assignment_ids[i % num_assignments]).id
end

puts "creating students"
student_user_ids = (1..num_students).map do |i|
  User.find_or_create_by!(name: "student#{i}") do |u|
    u.email = "student#{i}@example.com"
    u.password = "password"
    u.full_name = Faker::Name.name
    u.institution_id = inst_id
    u.role_id = 1
    u.parent_id = instructor_user_ids[i % num_instructors]
  end.id
end

puts "assigning students to teams, assignments, and participants"
num_students.times do |i|
  team_id = team_ids[i % num_teams]
  user_id = student_user_ids[i]

  TeamsUser.find_or_create_by!(team_id: team_id, user_id: user_id)

  participant = AssignmentParticipant.find_or_create_by!(user_id: user_id, parent_id: assignment_ids[i % num_assignments]) do |p|
    p.team_id = team_id
    p.handle = "student#{i + 1}"
  end

  TeamsParticipant.find_or_create_by!(team_id: team_id, participant_id: participant.id) do |tp|
    tp.user_id = user_id
  end
end

puts "creating questionnaires and items"
questionnaire = AuthorFeedbackQuestionnaire.find_or_create_by!(name: "Sample Review Questionnaire") do |q|
  q.instructor_id = 1
  q.private = false
  q.min_item_score = 0
  q.max_item_score = 5
end

# Items are keyed by their text
[
  {
    txt: "How clearly did the author explain the problem statement?",
    item_type: "Scale",
    weight: 1,
    break_before: true,
    min_label: "Strongly Disagree",
    max_label: "Strongly Agree"
  },
  {
    txt: "Provide detailed feedback on the author's solution approach.",
    item_type: "Textarea",
    weight: 1,
    break_before: true,
    size: "60,5"
  },
  {
    txt: "Rate the overall quality of the submission.",
    item_type: "Scale",
    weight: 2,
    break_before: true,
    min_label: "Poor",
    max_label: "Excellent"
  }
].each_with_index do |attrs, i|
  questionnaire.items.find_or_create_by!(txt: attrs[:txt]) do |item|
    item.assign_attributes(attrs.except(:txt).merge(seq: i + 1))
  end
end

puts "seeding complete"
