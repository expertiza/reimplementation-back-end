# frozen_string_literal: true

begin
  # Create an instritution
  inst_id = Institution.create!(
    name: 'North Carolina State University'
  ).id

  Role.create!(id: 1, name: 'Super Administrator')
  Role.create!(id: 2, name: 'Administrator')
  Role.create!(id: 3, name: 'Instructor')
  Role.create!(id: 4, name: 'Teaching Assistant')
  Role.create!(id: 5, name: 'Student')

  # Create an admin user
  User.create!(
    name: 'admin',
    email: 'admin2@example.com',
    password: 'password123',
    full_name: 'admin admin',
    institution_id: 1,
    role_id: 1
  )

  # Generate Random Users
  num_students = 48
  num_assignments = 8
  num_teams = 16
  num_courses = 2
  num_instructors = 2

  puts "creating instructors"
  instructor_user_ids = []
  num_instructors.times do
    instructor_user_ids << User.create(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",
      full_name: Faker::Name.name,
      institution_id: 1,
      role_id: 3
    ).id
  end

  puts "creating courses"
  course_ids = []
  num_courses.times do |i|
    course_ids << Course.create(
      instructor_id: instructor_user_ids[i],
      institution_id: inst_id,
      directory_path: Faker::File.dir(segment_count: 2),
      name: Faker::Company.industry,
      info: "A fake class",
      private: false
    ).id
  end

  puts "creating assignments"
  assignment_ids = []
  num_assignments.times do |i|
    assignment_ids << Assignment.create(
      name: Faker::Verb.base,
      instructor_id: instructor_user_ids[i % num_instructors],
      course_id: course_ids[i % num_courses],
      has_teams: true,
      private: false
    ).id
  end

  puts "creating teams"
  team_ids = []
  num_teams.times do |i|
    team_ids << AssignmentTeam.create(
      name: "Team #{i + 1}",
      parent_id: assignment_ids[i % num_assignments]
    ).id
  end

  puts "creating students"
  student_user_ids = []
  num_students.times do
    student_user_ids << User.create(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",
      full_name: Faker::Name.name,
      institution_id: 1,
      role_id: 5,
      parent_id: [nil, *instructor_user_ids].sample
    ).id
  end

  puts "assigning students to teams"
  teams_users_ids = []
  # num_students.times do |i|
  #  teams_users_ids << TeamsUser.create(
  #    team_id: team_ids[i%num_teams],
  #    user_id: student_user_ids[i]
  #  ).id
  # end

  num_students.times do |i|
    puts "Creating TeamsUser with team_id: #{team_ids[i % num_teams]}, user_id: #{student_user_ids[i]}"
    teams_user = TeamsUser.create(
      team_id: team_ids[i % num_teams],
      user_id: student_user_ids[i]
    )
    if teams_user.persisted?
      teams_users_ids << teams_user.id
      puts "Created TeamsUser with ID: #{teams_user.id}"
    else
      puts "Failed to create TeamsUser: #{teams_user.errors.full_messages.join(', ')}"
    end
  end

  puts "assigning participant to students, teams, courses, and assignments"
  participant_ids = []
  num_students.times do |i|
    participant = AssignmentParticipant.create(
      user_id: student_user_ids[i],
      parent_id: assignment_ids[i%num_assignments],
      team_id: team_ids[i%num_teams],
      handle: Faker::Internet.unique.username,
    )
    if participant.persisted?
      puts "Created AssignmentParticipant with ID: #{participant.id}"
      participant_ids << participant.id
      TeamsParticipant.create!(
        team_id: team_ids[i%num_teams],
        participant_id: participant.id,
        user_id: student_user_ids[i]
      )
    else
      puts "Failed to create AssignmentParticipant: #{participant.errors.full_messages.join(', ')}"
    end
  end

rescue ActiveRecord::RecordInvalid => e
  puts e, 'The db has already been seeded'
end

puts 'creating course report data'

course_report_course = Course.joins(:assignments).distinct.order(:id).first
raise('Seed at least one course with assignments before creating course report data') unless course_report_course

course_report_assignments = course_report_course.assignments.order(:id).to_a
course_report_assignment_ids = course_report_assignments.map(&:id)

course_report_user_ids = AssignmentParticipant
  .where(parent_id: course_report_assignment_ids)
  .where.not(user_id: nil)
  .distinct
  .pluck(:user_id)
course_report_users = User.where(id: course_report_user_ids).order(:id).to_a
raise('Seed at least one student participant in the selected course before creating course report data') if course_report_users.empty?

course_report_instructor = course_report_course.instructor || User.joins(:role).where(roles: { name: 'Instructor' }).order(:id).first
raise('Seed at least one instructor before creating course report data') unless course_report_instructor

def seed_course_report_participant(user, assignment)
  participant = AssignmentParticipant.find_or_initialize_by(user_id: user.id, parent_id: assignment.id)
  participant.handle ||= user.name
  participant.save!
  participant
end

def seed_course_report_team(assignment, index)
  team = AssignmentTeam.find_or_initialize_by(
    name: "Course Report Team #{assignment.id}-#{index + 1}",
    parent_id: assignment.id
  )
  team.grade_for_submission = 80 + ((assignment.id + index) % 16)
  team.save!
  team
end

def seed_course_report_members(team, participants)
  participants.each do |participant|
    team_member = TeamsParticipant.find_or_initialize_by(team_id: team.id, participant_id: participant.id)
    team_member.user_id = participant.user_id
    team_member.save!
  end
end

def seed_course_report_questionnaire(assignment, instructor)
  questionnaire = Questionnaire.find_or_create_by!(name: "Course Report Rubric #{assignment.id}") do |rubric|
    rubric.instructor_id = instructor.id
    rubric.private = false
    rubric.min_question_score = 0
    rubric.max_question_score = 5
    rubric.questionnaire_type = 'ReviewQuestionnaire'
    rubric.display_type = 'Review'
  end

  item = Criterion.find_or_create_by!(
    questionnaire_id: questionnaire.id,
    txt: "Course report score for assignment #{assignment.id}"
  ) do |criterion|
    criterion.weight = 1
    criterion.seq = 1
    criterion.question_type = 'Criterion'
    criterion.size = '50,3'
    criterion.break_before = true
  end

  AssignmentQuestionnaire.find_or_create_by!(
    assignment_id: assignment.id,
    questionnaire_id: questionnaire.id,
    used_in_round: nil
  )

  item
end

def seed_course_report_response(map, item, answer_value, comments)
  response = Response.find_or_initialize_by(map_id: map.id, round: nil)
  response.is_submitted = true
  response.save!

  answer = Answer.find_or_initialize_by(response_id: response.id, item_id: item.id)
  answer.answer = answer_value
  answer.comments = comments
  answer.save!

  response
end

def seed_course_report_review(assignment, reviewer, reviewee_team, item, score)
  map = ReviewResponseMap.find_or_create_by!(
    reviewed_object_id: assignment.id,
    reviewer_id: reviewer.id,
    reviewee_id: reviewee_team.id
  )
  seed_course_report_response(map, item, score, "Seed review from #{reviewer.user_name} to #{reviewee_team.name}")
  map
end

def seed_course_report_teammate_review(assignment, reviewer, reviewee, item, score)
  map = TeammateReviewResponseMap.find_or_create_by!(
    reviewed_object_id: assignment.id,
    reviewer_id: reviewer.id,
    reviewee_id: reviewee.id
  )
  seed_course_report_response(map, item, score, "Seed teammate review from #{reviewer.user_name} to #{reviewee.user_name}")
  map
end

def seed_course_report_author_feedback(review_map, reviewer, reviewee, item, score)
  map = FeedbackResponseMap.find_or_create_by!(
    reviewed_object_id: review_map.id,
    reviewer_id: reviewer.id,
    reviewee_id: reviewee.id
  )
  seed_course_report_response(map, item, score, "Seed author feedback from #{reviewer.user_name} to #{reviewee.user_name}")
end

course_report_assignments.each do |assignment|
  participants = course_report_users.map { |user| seed_course_report_participant(user, assignment) }
  item = seed_course_report_questionnaire(assignment, course_report_instructor)

  existing_team_groups = {}
  participants_without_teams = []

  participants.each do |participant|
    team = participant.team

    if team
      existing_team_groups[team.id] ||= [team, []]
      existing_team_groups[team.id][1] << participant
    else
      participants_without_teams << participant
    end
  end

  existing_teams_with_members = existing_team_groups.values.each_with_index.map do |(team, team_participants), team_index|
    team.update!(grade_for_submission: 80 + ((assignment.id + team_index) % 16))
    seed_course_report_members(team, team_participants)

    [team, team_participants]
  end

  seeded_teams_with_members = participants_without_teams.each_slice(2).with_index.map do |team_participants, team_index|
    team = seed_course_report_team(assignment, team_index)
    seed_course_report_members(team, team_participants)

    [team, team_participants]
  end

  teams_with_members = existing_teams_with_members + seeded_teams_with_members

  teams_with_members.each_with_index do |(team, _team_participants), team_index|
    if assignment.has_topics
      topics = ProjectTopic.where(assignment_id: assignment.id).order(:id).to_a
      if topics.any?
        SignedUpTeam.find_or_create_by!(team_id: team.id, project_topic_id: topics[team_index % topics.size].id) do |signup|
          signup.is_waitlisted = false
        end
      end
    end
  end

  teams_with_members.each_with_index do |(team, team_participants), team_index|
    reviewers = participants - team_participants
    reviewers = participants if reviewers.empty?

    reviewers.first(2).each_with_index do |reviewer, reviewer_index|
      review_score = 3 + ((assignment.id + team_index + reviewer_index) % 3)
      review_map = seed_course_report_review(assignment, reviewer, team, item, review_score)

      feedback_reviewer = team_participants[reviewer_index % team_participants.size]
      feedback_score = 3 + ((assignment.id + reviewer.id + team.id) % 3)
      seed_course_report_author_feedback(review_map, feedback_reviewer, reviewer, item, feedback_score)
    end

    team_participants.permutation(2).each_with_index do |(reviewer, reviewee), teammate_index|
      teammate_score = 3 + ((assignment.id + reviewer.id + reviewee.id + teammate_index) % 3)
      seed_course_report_teammate_review(assignment, reviewer, reviewee, item, teammate_score)
    end
  end
end

puts "Course report seed course id: #{course_report_course.id}"
