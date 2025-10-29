# frozen_string_literal: true

# Keep Faker's unique generators from exhausting across reseeds
Faker::UniqueGenerator.clear if defined?(Faker)

ActiveRecord::Base.transaction do
  inst = Institution.find_or_create_by!(name: 'North Carolina State University')

  # Canonical roles your app expects
  super_admin     = Role.find_or_create_by!(name: 'Super Administrator')
  instructor_role = Role.find_or_create_by!(name: 'Instructor')
  student_role    = Role.find_or_create_by!(name: 'Student')

  # Admin user
  User.find_or_create_by!(email: 'admin2@example.com') do |u|
    u.name           = 'admin'
    u.password       = 'password123'
    u.full_name      = 'admin admin'
    u.institution_id = inst.id
    u.role_id        = super_admin.id
  end

  # Admin instructor
  User.find_or_create_by!(email: 'instructor@example.com') do |u|
    u.name           = 'instructor'
    u.password       = 'password123'
    u.full_name      = 'instructor instructor'
    u.institution_id = inst.id
    u.role_id        = instructor_role.id
  end

  # =====================================================================
  # Bulk generation (idempotent-friendly where names/emails can collide)
  # =====================================================================
  num_students    = 48
  num_assignments = 8
  num_teams       = 16
  num_courses     = 2
  num_instructors = 2

  puts 'creating instructors'
  instructor_user_ids = []
  num_instructors.times do
    email = Faker::Internet.unique.email
    u = User.find_or_create_by!(email: email) do |x|
      x.name           = email.split('@').first
      x.password       = 'password'
      x.full_name      = Faker::Name.name
      x.institution_id = inst.id
      x.role_id        = instructor_role.id
    end
    instructor_user_ids << u.id
  end

  puts 'creating courses'
  course_ids = []
  num_courses.times do |i|
    cname = Faker::Company.industry
    c = Course.find_or_create_by!(name: cname, instructor_id: instructor_user_ids[i]) do |x|
      x.institution_id = inst.id
      x.directory_path = Faker::File.dir(segment_count: 2)
      x.info           = 'A fake class'
      x.private        = false
    end
    course_ids << c.id
  end

  puts 'creating assignments'
  assignment_ids = []
  num_assignments.times do |i|
    aname = (Faker::Verb.unique.base rescue Faker::Verb.base)
    a = Assignment.find_or_create_by!(name: aname, course_id: course_ids[i % num_courses]) do |x|
      x.instructor_id = instructor_user_ids[i % num_instructors]
      x.has_teams     = true
      x.private       = false
    end
    assignment_ids << a.id
  end

  puts 'creating teams'
  team_ids = []
  num_teams.times do |i|
    parent_id = assignment_ids[i % num_assignments]
    # Make team name unique per assignment and across reseeds
    tname = "Team #{i + 1}-A#{parent_id}"
    t = AssignmentTeam.find_or_create_by!(name: tname, parent_id: parent_id)
    team_ids << t.id
  end

  puts 'creating students'
  student_user_ids = []
  num_students.times do
    email = Faker::Internet.unique.email
    u = User.find_or_create_by!(email: email) do |x|
      x.name           = Faker::Internet.username
      x.password       = 'password'
      x.full_name      = Faker::Name.name
      x.institution_id = inst.id
      x.role_id        = student_role.id
    end
    student_user_ids << u.id
  end

  puts 'assigning students to teams'
  teams_users_ids = []
  num_students.times do |i|
    tu = TeamsUser.find_or_create_by!(team_id: team_ids[i % num_teams], user_id: student_user_ids[i])
    teams_users_ids << tu.id
  end

  puts 'assigning participant to students, teams, courses, and assignments'
  participant_ids = []
  num_students.times do |i|
    parent_id = assignment_ids[i % num_assignments]
    ap = AssignmentParticipant.find_or_create_by!(user_id: student_user_ids[i], parent_id: parent_id) do |p|
      p.team_id = team_ids[i % num_teams]
      p.handle  = Faker::Internet.unique.username
    end
    participant_ids << ap.id
  end

  # =====================================================================
  # Seed review mappings (only if the model/table exist)
  # =====================================================================
  if defined?(ReviewMapping) && ActiveRecord::Base.connection.table_exists?('review_mappings')
    puts 'creating review mappings (2 reviewers per team, from different teams in same assignment)'

    # Helper to check column presence safely
    review_mapping_columns = ReviewMapping.column_names

    created_count = 0
    team_ids.each do |tid|
      team = AssignmentTeam.find_by(id: tid)
      next unless team

      assignment_id = team.parent_id
      # all participants for this assignment, excluding current team members
      eligible_reviewers = AssignmentParticipant
      .where(parent_id: assignment_id)
      .where.not(team_id: team.id)
      .to_a

      # pick 2 unique reviewers if possible
      reviewers = eligible_reviewers.sample([2, eligible_reviewers.size].min)

      reviewers.each do |ap|
        # Build attributes dynamically based on what columns exist
        attrs = {}
        attrs[:team_id]        = team.id                      if review_mapping_columns.include?('team_id')
        attrs[:assignment_id]  = assignment_id                if review_mapping_columns.include?('assignment_id')
        attrs[:reviewer_id]    = ap.id                        if review_mapping_columns.include?('reviewer_id')
        attrs[:reviewer_user_id] = ap.user_id                 if review_mapping_columns.include?('reviewer_user_id')
        attrs[:round]          = 1                            if review_mapping_columns.include?('round')
        attrs[:type]           = 'ReviewMapping'              if review_mapping_columns.include?('type')

        # Use a minimal identity for idempotency:
        # Prefer a composite of reviewer + team (+ assignment if present)
        identity = {
          reviewer_id: attrs[:reviewer_id],
          team_id:     attrs[:team_id]
        }.compact
        identity[:assignment_id] = attrs[:assignment_id] if attrs[:assignment_id]

        # Fall back if the essential identity columns aren't present
        if identity.empty?
          ReviewMapping.create!(attrs)
          created_count += 1
        else
          ReviewMapping.find_or_create_by!(identity) do |rm|
            attrs.each { |k, v| rm[k] = v }
          end
          created_count += 1
        end
      end
    end

    puts "created/ensured #{created_count} review_mappings"
  else
    puts 'review_mappings table/model not present; skipping review mapping seeding'
  end

  # =====================================================================
  # PAST-DUE ASSIGNMENT (with team + enrolled student)
  # =====================================================================
  puts 'creating past-due assignment + team + enrollment'
  instructor = User.find_by!(email: 'instructor@example.com')

  course = Course.find_or_create_by!(
    name: 'CSC517 – Past-Due Sandbox',
    instructor_id: instructor.id
  ) do |x|
    x.institution_id = inst.id
    x.directory_path = 'csc517/past_due'
    x.info           = 'Seeded course for testing past-due behavior'
    x.private        = false
  end

  past_asg = Assignment.find_or_create_by!(
    name: 'PAST: Project 0',
    course_id: course.id
  ) do |x|
    x.instructor_id = instructor.id
    x.has_teams     = true
    x.private       = false
  end

  # Mark "past due": add/update a submission deadline in the past
  DueDate.find_or_create_by!(
    parent_type:  'Assignment',
    parent_id:    past_asg.id,
    type:         'AssignmentDueDate',
    deadline_name: 'submission (seed)'
  ) do |dd|
    dd.deadline_type_id      = 1  # e.g., submission
    dd.submission_allowed_id = 1
    dd.review_allowed_id     = 1
    dd.due_at                = 2.days.ago
  end

  past_team = AssignmentTeam.find_or_create_by!(
    name: 'Past Team Alpha',
    parent_id: past_asg.id
  )

  student_id = User.joins(:role).where(roles: { name: 'Student' }).limit(1).pluck(:id).first ||
               User.create!(
                 email:          'seedstudent@example.com',
                 name:           'seedstudent',
                 password:       'password123',
                 full_name:      'Seed Student',
                 institution_id: inst.id,
                 role_id:        student_role.id
               ).id

  TeamsUser.find_or_create_by!(team_id: past_team.id, user_id: student_id)

  AssignmentParticipant.find_or_create_by!(user_id: student_id, parent_id: past_asg.id) do |p|
    p.team_id = past_team.id
    p.handle  = Faker::Internet.unique.username
  end

  # Also seed a couple of review mappings for the past-due team if schema allows
  if defined?(ReviewMapping) && ActiveRecord::Base.connection.table_exists?('review_mappings')
    review_mapping_columns = ReviewMapping.column_names
    eligible = AssignmentParticipant.where(parent_id: past_asg.id).where.not(team_id: past_team.id).to_a.sample(2)
    eligible.each do |ap|
      attrs = {}
      attrs[:team_id]        = past_team.id                  if review_mapping_columns.include?('team_id')
      attrs[:assignment_id]  = past_asg.id                   if review_mapping_columns.include?('assignment_id')
      attrs[:reviewer_id]    = ap.id                         if review_mapping_columns.include?('reviewer_id')
      attrs[:reviewer_user_id] = ap.user_id                  if review_mapping_columns.include?('reviewer_user_id')
      attrs[:round]          = 1                             if review_mapping_columns.include?('round')
      attrs[:type]           = 'ReviewMapping'               if review_mapping_columns.include?('type')

      identity = {
        reviewer_id: attrs[:reviewer_id],
        team_id:     attrs[:team_id]
      }.compact
      identity[:assignment_id] = attrs[:assignment_id] if attrs[:assignment_id]

      if identity.empty?
        ReviewMapping.create!(attrs)
      else
        ReviewMapping.find_or_create_by!(identity) do |rm|
          attrs.each { |k, v| rm[k] = v }
        end
      end
    end
  end

  puts "Seeded past-due assignment #{past_asg.id} with team #{past_team.id} and student #{student_id}"
end

puts 'Seed completed.'
