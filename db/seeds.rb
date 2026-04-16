# frozen_string_literal: true

# --- Bootstrap (safe to re-run): institution, roles, admin ---

institution = Institution.find_or_create_by!(name: 'North Carolina State University')
inst_id = institution.id

# Role primary keys must match Role::STUDENT_ID, Role::INSTRUCTOR_ID, etc. (see app/models/role.rb).
[
  [Role::STUDENT_ID, 'Student'],
  [Role::TEACHING_ASSISTANT_ID, 'Teaching Assistant'],
  [Role::INSTRUCTOR_ID, 'Instructor'],
  [Role::ADMINISTRATOR_ID, 'Administrator'],
  [Role::SUPER_ADMINISTRATOR_ID, 'Super Administrator']
].each do |id, name|
  Role.find_or_create_by!(id: id) { |r| r.name = name }
end

User.find_or_create_by!(email: 'admin2@example.com') do |u|
  u.name = 'admin'
  u.password = 'password123'
  u.full_name = 'admin admin'
  u.institution_id = inst_id
  u.role_id = Role::SUPER_ADMINISTRATOR_ID
end

# --- Bulk faker demo (only if no assignments yet) ---

unless Assignment.exists?
  num_students = 48
  num_assignments = 8
  num_teams = 16
  num_courses = 2
  num_instructors = 2

  puts "creating instructors"
  instructor_user_ids = []
  num_instructors.times do
    instructor_user_ids << User.create!(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",
      full_name: Faker::Name.name,
      institution_id: inst_id,
      role_id: Role::INSTRUCTOR_ID
    ).id
  end

  puts "creating courses"
  course_ids = []
  num_courses.times do |i|
    course_ids << Course.create!(
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
    assignment_ids << Assignment.create!(
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
    team_ids << AssignmentTeam.create!(
      name: "Team #{i + 1}",
      parent_id: assignment_ids[i % num_assignments]
    ).id
  end

  puts "creating students"
  student_user_ids = []
  num_students.times do
    student_user_ids << User.create!(
      name: Faker::Internet.unique.username,
      email: Faker::Internet.unique.email,
      password: "password",
      full_name: Faker::Name.name,
      institution_id: inst_id,
      role_id: Role::STUDENT_ID,
      parent_id: [nil, *instructor_user_ids].sample
    ).id
  end

  puts "assigning students to teams"
  teams_users_ids = []
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
      parent_id: assignment_ids[i % num_assignments],
      team_id: team_ids[i % num_teams],
      handle: Faker::Internet.unique.username
    )
    if participant.persisted?
      puts "Created AssignmentParticipant with ID: #{participant.id}"
      participant_ids << participant.id
      TeamsParticipant.create!(
        team_id: team_ids[i % num_teams],
        participant_id: participant.id,
        user_id: student_user_ids[i]
      )
    else
      puts "Failed to create AssignmentParticipant: #{participant.errors.full_messages.join(', ')}"
    end
  end
else
  puts 'Skipping bulk faker seed (assignments already exist).'
end

# --- Calibration demo (runs every seed; idempotent) ---

puts 'seeding calibration demo data (idempotent)'

demo_assignment = Assignment.order(:id).first
unless demo_assignment
  puts 'No assignments in database; skip calibration demo.'
else
  demo_instructor_id = demo_assignment.instructor_id

  rubric = Questionnaire.find_or_create_by!(name: 'Seed calibration rubric', instructor_id: demo_instructor_id) do |q|
    q.private = false
    q.min_question_score = 0
    q.max_question_score = 5
    q.questionnaire_type = 'ReviewQuestionnaire'
    q.display_type = 'Review'
  end

  if rubric.items.empty?
    3.times do |i|
      Item.create!(
        questionnaire: rubric,
        seq: i + 1,
        txt: "Criterion #{i + 1}: demonstration quality",
        weight: 1,
        question_type: 'CriterionItem',
        size: '5,3',
        break_before: true,
        min_label: 'Poor',
        max_label: 'Excellent'
      )
    end
  end

  aq_link = AssignmentQuestionnaire.find_or_initialize_by(assignment_id: demo_assignment.id, questionnaire_id: rubric.id)
  aq_link.used_in_round = 1
  aq_link.notification_limit = 15
  aq_link.save!

  student_parts = AssignmentParticipant
                  .where(parent_id: demo_assignment.id)
                  .joins(:user)
                  .where(users: { role_id: Role::STUDENT_ID })
                  .order(:id)
                  .limit(4)
                  .to_a

  if student_parts.size < 3
    puts "Skipping calibration maps: need 3+ student participants on assignment #{demo_assignment.id} (have #{student_parts.size})."
  else
    reviewee = student_parts[0]
    peer_a = student_parts[1]
    peer_b = student_parts[2]

    inst_user = User.find(demo_instructor_id)
    inst_part = AssignmentParticipant.find_or_initialize_by(parent_id: demo_assignment.id, user_id: demo_instructor_id)
    if inst_part.new_record?
      inst_part.handle = inst_user.name
      inst_part.can_review = true
      inst_part.can_submit = false
      inst_part.save!
    end

    ins_map = ResponseMap.find_or_initialize_by(
      reviewed_object_id: demo_assignment.id,
      reviewer_id: inst_part.id,
      reviewee_id: reviewee.id
    )
    ins_map.for_calibration = true
    ins_map.save!

    inst_resp = Response.find_or_initialize_by(map_id: ins_map.id)
    inst_resp.round = 1
    inst_resp.is_submitted = true
    inst_resp.additional_comment = 'Instructor calibration (gold standard).'
    inst_resp.save!

    rubric.items.order(:seq).find_each do |item|
      ans = Answer.find_or_initialize_by(response_id: inst_resp.id, item_id: item.id)
      ans.answer = 4
      ans.comments = 'Aligned with expectations.'
      ans.save!
    end

    [[peer_a, [3, 4, 5]], [peer_b, [2, 4, 4]]].each do |peer, scores|
      sm = ResponseMap.find_or_initialize_by(
        reviewed_object_id: demo_assignment.id,
        reviewer_id: peer.id,
        reviewee_id: reviewee.id
      )
      sm.for_calibration = true
      sm.save!
      sr = Response.find_or_initialize_by(map_id: sm.id)
      sr.round = 1
      sr.is_submitted = true
      sr.additional_comment = 'Student calibration review.'
      sr.save!
      rubric.items.order(:seq).each_with_index do |item, i|
        ans = Answer.find_or_initialize_by(response_id: sr.id, item_id: item.id)
        ans.answer = scores[i] || 3
        ans.comments = "Student score #{scores[i] || 3}"
        ans.save!
      end
    end

    team = reviewee.team
    if team
      links = team.hyperlinks
      demo_link = 'https://example.edu/calibration-demo-submission'
      unless links.include?(demo_link)
        team.update!(submitted_hyperlinks: YAML.dump(links + [demo_link]))
      end
    end
  end
end

puts 'db:seed finished.'
