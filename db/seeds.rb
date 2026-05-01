# frozen_string_literal: true

def seed_assignment_grades
  puts "assigning seeded grades"

  AssignmentTeam.order(:id).find_each.with_index do |team, index|
    team.update!(
      grade_for_submission: team.grade_for_submission || 80 + (index % 16),
      comment_for_submission: team.comment_for_submission.presence || "Seeded grade for #{team.name}"
    )
  end

  AssignmentParticipant.order(:id).find_each.with_index do |participant, index|
    next unless (index % 5).zero?
    next if participant.grade.present?

    participant.update!(grade: 85 + (index % 10))
  end
end

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

  puts "creating project topics"
  project_topic_ids = []
  assignment_ids.each_with_index do |assignment_id, assignment_index|
    3.times do |topic_index|
      topic_number = assignment_index * 3 + topic_index + 1
      project_topic = ProjectTopic.create(
        assignment_id: assignment_id,
        topic_identifier: "T#{topic_number}",
        topic_name: "Project Topic #{topic_number}",
        category: ["Design", "Implementation", "Testing"].sample,
        max_choosers: rand(1..3),
        description: "Seeded project topic #{topic_number} for assignment #{assignment_id}",
        link: "https://example.com/project_topics/#{topic_number}"
      )

      if project_topic.persisted?
        project_topic_ids << project_topic.id
        puts "Created ProjectTopic with ID: #{project_topic.id}"
      else
        puts "Failed to create ProjectTopic: #{project_topic.errors.full_messages.join(', ')}"
      end
    end
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

  puts "assigning students to courses"
  course_participant_ids = []
  num_students.times do |i|
    course_participant = CourseParticipant.create(
      user_id: student_user_ids[i],
      parent_id: course_ids[i % num_courses],
      handle: Faker::Internet.unique.username
    )

    if course_participant.persisted?
      puts "Created CourseParticipant with ID: #{course_participant.id}"
      course_participant_ids << course_participant.id
    else
      puts "Failed to create CourseParticipant: #{course_participant.errors.full_messages.join(', ')}"
    end
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

  seed_assignment_grades

  puts "creating questionnaires with items, question advices, and answers"
  questionnaire_blueprints = [
    {
      name: 'Seed Review Questionnaire',
      questionnaire_type: 'ReviewQuestionnaire',
      display_type: 'Likert',
      instruction_loc: 'seed/review_instructions',
      items: [
        {
          txt: 'How clear is the overall design?',
          weight: 5,
          seq: 1,
          question_type: 'Scale',
          break_before: true,
          advices: [
            { score: 1, advice: 'Start by clarifying the main design goal.' },
            { score: 5, advice: 'Highlight the strongest design tradeoffs and rationale.' }
          ]
        },
        {
          txt: 'How complete is the implementation?',
          weight: 4,
          seq: 2,
          question_type: 'Scale',
          break_before: true,
          advices: [
            { score: 2, advice: 'Point out the missing edge cases and incomplete flows.' },
            { score: 4, advice: 'Call out the implemented features that work end-to-end.' }
          ]
        }
      ]
    },
    {
      name: 'Seed Teammate Review Questionnaire',
      questionnaire_type: 'TeammateReviewQuestionnaire',
      display_type: 'Likert',
      instruction_loc: 'seed/teammate_review_instructions',
      items: [
        {
          txt: 'How effectively did this teammate communicate?',
          weight: 3,
          seq: 1,
          question_type: 'Scale',
          break_before: true,
          advices: [
            { score: 1, advice: 'Share examples of communication gaps and missed updates.' },
            { score: 3, advice: 'Mention consistent coordination and timely follow-ups.' }
          ]
        },
        {
          txt: 'How reliable was this teammate in meeting commitments?',
          weight: 5,
          seq: 2,
          question_type: 'Scale',
          break_before: true,
          advices: [
            { score: 2, advice: 'Describe any late or incomplete deliverables.' },
            { score: 5, advice: 'Recognize steady, dependable contribution across milestones.' }
          ]
        }
      ]
    },
    {
      name: 'Seed Survey Questionnaire',
      questionnaire_type: 'SurveyQuestionnaire',
      display_type: 'Likert',
      instruction_loc: 'seed/survey_instructions',
      items: [
        {
          txt: 'How useful were the project materials?',
          weight: 4,
          seq: 1,
          question_type: 'Scale',
          break_before: true,
          advices: [
            { score: 1, advice: 'Note which project materials were hard to use or missing.' },
            { score: 4, advice: 'Mention the resources that were especially helpful.' }
          ]
        },
        {
          txt: 'How confident do you feel about the project goals?',
          weight: 4,
          seq: 2,
          question_type: 'Scale',
          break_before: true,
          advices: [
            { score: 2, advice: 'Explain where the goals or requirements still feel unclear.' },
            { score: 4, advice: 'Explain which goals are now clearly understood.' }
          ]
        }
      ]
    }
  ]

  questionnaire_blueprints.each_with_index do |blueprint, index|
    instructor = Instructor.find(instructor_user_ids[index % instructor_user_ids.length])
    assignment_id = assignment_ids[index % assignment_ids.length]
    assignment_participants = AssignmentParticipant.where(parent_id: assignment_id).order(:id).limit(2)

    questionnaire = Questionnaire.create!(
      name: blueprint[:name],
      instructor: instructor,
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      questionnaire_type: blueprint[:questionnaire_type],
      display_type: blueprint[:display_type],
      instruction_loc: blueprint[:instruction_loc]
    )

    response = nil
    if assignment_participants.size == 2
      response_map = ResponseMap.create!(
        reviewer_id: assignment_participants.first.id,
        reviewee_id: assignment_participants.second.id,
        reviewed_object_id: assignment_id
      )

      response = Response.create!(
        map_id: response_map.id,
        additional_comment: "Seeded response for #{questionnaire.name}",
        is_submitted: true,
        round: 1,
        version_num: 1
      )
    end

    blueprint[:items].each do |item_blueprint|
      item = Item.create!(
        questionnaire: questionnaire,
        txt: item_blueprint[:txt],
        weight: item_blueprint[:weight],
        seq: item_blueprint[:seq],
        question_type: item_blueprint[:question_type],
        break_before: item_blueprint[:break_before]
      )

      item_blueprint[:advices].each do |advice_blueprint|
        QuestionAdvice.create!(
          item: item,
          score: advice_blueprint[:score],
          advice: advice_blueprint[:advice]
        )
      end

      next unless response

      Answer.create!(
        item: item,
        response: response,
        answer: rand(questionnaire.min_question_score..questionnaire.max_question_score),
        comments: "Seeded answer for #{item.txt}"
      )
    end
  end

rescue ActiveRecord::RecordInvalid => e
  puts e, 'The db has already been seeded'
  seed_assignment_grades
end
