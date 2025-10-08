# frozen_string_literal: true

begin
    #Create an institution
    inst_id = Institution.create!(
      name: 'North Carolina State University',
    ).id
    
    roles = {
      admin: Role.find_or_create_by!(name: 'Super Administrator'),
      administrator: Role.find_or_create_by!(name: 'Administrator'),
      instructor: Role.find_or_create_by!(name: 'Instructor'),
      ta: Role.find_or_create_by!(name: 'Teaching Assistant'),
      student: Role.find_or_create_by!(name: 'Student')
    }
    

    # Create an admin user
    User.create!(
      name: 'admin',
      email: 'admin2@example.com',
      password: 'password123',
      full_name: 'admin admin',
      institution_id: 1,
      role_id:  roles[:admin].id,
    )
    puts "creating standard test students"
    test_students = [
      { name: 'alice', full_name: 'Alice Johnson', email: 'alice@example.com' },
      { name: 'bob', full_name: 'Bob Smith', email: 'bob@example.com' },
      { name: 'charlie', full_name: 'Charlie Davis', email: 'charlie@example.com' },
      { name: 'diana', full_name: 'Diana Martinez', email: 'diana@example.com' },
      { name: 'ethan', full_name: 'Ethan Brown', email: 'ethan@example.com' },
      { name: 'fiona', full_name: 'Fiona Wilson', email: 'fiona@example.com' }
    ]

    test_students.each do |student_data|
      User.find_or_create_by!(email: student_data[:email]) do |user|
        user.name = student_data[:name]
        user.full_name = student_data[:full_name]
        user.password = 'password123'
        user.institution_id = 1
        user.role_id = roles[:student].id
        user.handle = student_data[:name]
      end
    end
    puts "✅ Created #{test_students.count} standard test students"
    

    #Generate Random Users
    num_students = 46
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
        role_id:  roles[:instructor].id,
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
        instructor_id: instructor_user_ids[i%num_instructors],
        course_id: 2,
        has_teams: true,
        private: false
      ).id
    end


    puts "creating assignment teams"
    team_ids = []
    (num_teams/2).times do |i|
      # assignment_id = assignment_ids[i % num_assignments]
      team = AssignmentTeam.create(
        parent_id: 1,
        type: 'AssignmentTeam',
        name: Faker::Internet.unique.username(separators: [' ']),
      )

      if team.persisted?
        team_ids << team.id
        puts "Created AssignmentTeam with ID: #{team.id} for assignment_id: 1"
      else
        puts "Failed to create AssignmentTeam: #{team.errors.full_messages.join(', ')}"
      end
    end

    puts "creating course teams"
    (num_teams/2).times do |i|
      # course_id = course_ids[i % num_courses]
      team = CourseTeam.create(
        parent_id: 2,
        type: 'CourseTeam',
        name: Faker::Internet.unique.username(separators: [' ']),
      )

      if team.persisted?
        team_ids << team.id
        puts "Created CourseTeam with ID: #{team.id} for course_id: 1"
      else
        puts "Failed to create CourseTeam: #{team.errors.full_messages.join(', ')}"
      end
    end

    puts "creating students"
    student_user_ids = []
    num_students.times do
      student_user_ids << User.create(
        name: Faker::Internet.unique.username(separators: ['_']),
        email: Faker::Internet.unique.email,
        password: "password",
        full_name: Faker::Name.name,
        institution_id: 1,
        role_id:  roles[:student].id,
        handle: Faker::Internet.unique.username(separators: ['-'])
      ).id
    end

    # puts "assigning students to teams"
    # teams_users_ids = []
    # num_students.times do |i|
    #  teams_users_ids << TeamsUser.create(
    #    team_id: team_ids[i%num_teams],
    #    user_id: student_user_ids[i]
    #  ).id
    # end

    puts "assigning participant to students, teams, courses, and assignments"
    participant_ids = []
    teams_participant_ids = []
    (num_students/2).times do |i|
      user_id = student_user_ids[i]
      handle = User.find(user_id).handle
      participant = Participant.create(
        user_id: user_id,
        parent_id: 1,
        team_id: team_ids[i%num_teams],
        type: 'AssignmentParticipant',
        handle: handle
      )

      if participant.persisted?
        participant_ids << participant.id
        puts "Created assignment participant #{participant.id}"

        teams_participant = TeamsParticipant.create(
          participant_id: participant.id,
          team_id: participant.team_id,
          user_id: participant.user_id          
        )
        if teams_participant.persisted?
          teams_participant_ids << teams_participant.id
          puts "Created TeamsParticipant ID: #{teams_participant.id}"
        else
          puts "Failed to create TeamsParticipant: #{teams_participant.errors.full_messages.join(', ')}"
        end        
      else
        puts "Failed to create assignment participant: #{participant.errors.full_messages.join(', ')}"
      end
    end

    ((num_students / 2)..num_students-1).each do |i|
      user_id = student_user_ids[i]
      handle = User.find(user_id).handle
      participant = Participant.create(
        user_id: user_id,
        parent_id: course_ids[i%num_courses],
        team_id: team_ids[i%num_teams],
        type: 'CourseParticipant',
        handle: handle
      )

      if participant.persisted?
        participant_ids << participant.id
        puts "Created course participant #{participant.id}"
      else
        puts "Failed to create course participant: #{participant.errors.full_messages.join(', ')}"
      end
    end

    puts "creating questionnaires"
    questionnaire_count = 4
    items_per_questionnaire = 10
    questionnaire_ids = []
    questionnaire_count.times do
        questionnaire_ids << Questionnaire.create!(
        name: "#{Faker::Lorem.words(number: 5).join(' ').titleize}",
        instructor_id: rand(1..5), # assuming some instructor IDs exist in range 1–5
        private: false,
        min_question_score: 0,
        max_question_score: 5,
        questionnaire_type: "ReviewQuestionnaire",
        display_type: "Review",
        created_at: Time.now,
        updated_at: Time.now
        ).id

    end

    questionnaires = Questionnaire.all

    puts  "creating items for each questionnaire"
    questionnaires.each do |questionnaire|
        items_per_questionnaire.times do |i|
        Item.create!(
            txt: Faker::Lorem.sentence(word_count: 8),
            weight: rand(1..2),
            seq: i + 1,
            question_type: ['Criterion', 'Scale', 'TextArea', 'Dropdown'].sample,
            size: ['50x3', '60x4', '40x2'].sample,
            alternatives: ['Yes|No', 'Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree'],
            break_before: true,
            max_label: Faker::Lorem.word.capitalize,
            min_label: Faker::Lorem.word.capitalize,
            questionnaire_id: questionnaire.id,
            created_at: Time.now,
            updated_at: Time.now
        )
        end
    end


    # Use the first 2 created assignments
    first_two_assignment_ids = assignment_ids.first(2)
    used_in_rounds = [1, 2]
    questionnaire_id = 1

    first_two_assignment_ids.each do |assignment_id|
      # Check if assignment exists before creating AssignmentQuestionnaire
      if Assignment.exists?(assignment_id)
        used_in_rounds.each do |round|
          AssignmentQuestionnaire.create!(
            assignment_id: assignment_id,
            questionnaire_id: questionnaire_id,
            used_in_round: round
          )
          questionnaire_id += 1
        end
      end
    end

  # Fetch all reviewee teams (assuming AssignmentTeam model)
  # reviewee_teams = AssignmentTeam.limit(5)
  # reviewer_ids = Participant.pluck(:id).sample(10)

  # 5.times do |i|
  #   ReviewResponseMap.create!(
  #     reviewed_object_id: 1,
  #     reviewer_id: reviewer_ids[i],
  #     reviewee_id: 1,
  #     created_at: Time.now,
  #     updated_at: Time.now,
  #   )                                                                        
  # end

  # 5.times do |i|
  #   ReviewResponseMap.create!(
  #     reviewed_object_id: 1,
  #     reviewer_id: reviewer_ids[i],
  #     reviewee_id: 1,
  #     created_at: Time.now,
  #     updated_at: Time.now,
  #   )                                                                        
  # end

  # puts "Seeded review_response_maps and teammate_review_response_maps for 1 team, total: 10 records."

  # item_ids = Item.pluck(:id).sort  # 40 items total
  # response_records = []
  # items = Item.all

  # response_maps_count = ResponseMap.all.size*2
  # response_maps_count.times do |i|
  #   # item_id = item_ids[i / 5]            # Each item_id appears in 5 responses
  #   round = case i
  #           when 0...50 then 1
  #           when 50...100 then 2
  #           when 100...150 then 1
  #           else 2
  #           end

  #   map_id = if i < 100
  #             (i % 5) + 1              # map_id from 1 to 5
  #           else
  #             ((i - 100) % 5) + 6      # map_id from 6 to 10
  #           end

  #   response = Response.create!(
  #     map_id: map_id,
  #     round: round,
  #     is_submitted: true,
  #     version_num: 1,
  #     created_at: Time.now,
  #     updated_at: Time.now
  #   )

  #    items.each do |item|
  #     Answer.create(
  #       response: response,
  #       item: item,
  #       score: rand(0..5),
  #       comments: "Seeded answer"
  #     )

  #   # response_records << { item_id: item_id, response_id: response.id }
  # end

  # puts "✅ Seeded #{response_records.size} responses."

  # # Create answers
  # response_records.each do |rec|
  #   item = Item.find(rec[:item_id])
  #   answer = item.question_type=="Criterion" ? rand(0..5) : rand(0..1)
  #   Answer.create!(
  #     item_id: rec[:item_id],
  #     response_id: rec[:response_id],
  #     answer: answer,
  #     comments: Faker::Lorem.sentence
  #   )
  # end

  # puts "✅ Seeded #{response_records.size} answers."

  # Setup sample questions
  # questionnaire = Questionnaire.create!(name: "Sample Review Rubric", max_question_score: 5, min_question_score: 0, questionnaire_type: "ReviewQuestionnaire" ,display_type: "Review", instructor_id: 2, private: false)
  # items = []
  # 5.times do |i|
  #   items << Item.create!(
  #     txt: Faker::Lorem.sentence(word_count: 8),
  #     weight: rand(1..2),
  #     seq: i + 1,
  #     question_type: ['Criterion', 'Scale', 'TextArea', 'Dropdown'].sample,
  #     size: ['50x3', '60x4', '40x2'].sample,
  #     alternatives: ['Yes|No', 'Strongly Agree|Agree|Neutral|Disagree|Strongly Disagree'],
  #     break_before: true,
  #     max_label: Faker::Lorem.word.capitalize,
  #     min_label: Faker::Lorem.word.capitalize,
  #     questionnaire_id: questionnaire.id,
  #     created_at: Time.now,
  #     updated_at: Time.now
  # )
  # end

  # # Create 3 participants and 1 reviewee team
  # team = AssignmentTeam.find(1)
  # 3.times do |i|
  #   reviewer = AssignmentParticipant.find(i+1)

  #   # Create ResponseMap (reviewer -> team)
  #   map = ReviewResponseMap.create(
  #     reviewer_id: reviewer.id,
  #     reviewee_id: team.id,
  #     reviewed_object_id: 1,
  #     created_at: Time.now,
  #     updated_at: Time.now
  #   )

  #   # Create 2 Responses per map (one per round)
  #   [1, 2].each do |round|
  #     response = Response.create(
  #       map_id: map.id,
  #       round: round,
  #       is_submitted: true,
  #       created_at: Time.now,
  #       updated_at: Time.now,
  #     )

  #     # Create Answers for each question
  #     items.each do |item|
  #       Answer.create(
  #         response_id: response.id,
  #         item_id: item.id,
  #         answer: rand(1..5),
  #         comments: "Seeded answer"
  #       )
  #     end
  #   end
  # end

  # NOTE: ReviewResponseMap creation is commented out due to model issues with parent_id column
  # questionnaires = {}

  # (1..2).each do |round|
  #   questionnaire = Questionnaire.create!(
  #     name: "Review Rubric - Round #{round}",
  #     max_question_score: 5,
  #     min_question_score: 0,
  #     questionnaire_type: "ReviewQuestionnaire",
  #     display_type: "Review",
  #     instructor_id: 2,
  #     private: false
  #   )

  #   # Save questionnaire and its items
  #   questionnaires[round] = {
  #     q: questionnaire,
  #     items: []
  #   }

  #   5.times do |i|
  #     item = Item.create!(
  #       txt: Faker::Lorem.sentence(word_count: 8),
  #       weight: rand(1..2),
  #       seq: i + 1,
  #       question_type: ['Criterion', 'Scale', 'TextArea', 'Dropdown'].sample,
  #       size: ['50x3', '60x4', '40x2'].sample,
  #       alternatives: 'Yes|No',
  #       break_before: true,
  #       max_label: Faker::Lorem.word.capitalize,
  #       min_label: Faker::Lorem.word.capitalize,
  #       questionnaire_id: questionnaire.id
  #     )
  #     questionnaires[round][:items] << item
  #   end
  # end

  # # Create team and reviewers
  # puts "Creating review response maps..."
  # team = AssignmentTeam.find(1)

  # 3.times do |i|
  #   reviewer = AssignmentParticipant.find(i + 1)
  #   puts "Creating map for reviewer #{reviewer.id}, reviewee #{team.id}, assignment #{assignment_ids.first}"

  #   map = ReviewResponseMap.create!(
  #     reviewer_id: reviewer.id,
  #     reviewee_id: team.id,
  #     reviewed_object_id: assignment_ids.first # Use the first assignment ID
  #   )
  #   puts "Created ReviewResponseMap ID: #{map.id}"

  #   [1, 2].each do |round|
  #     response = Response.create!(
  #       map_id: map.id,
  #       round: round,
  #       is_submitted: true
  #     )

  #     # Get the correct items for this round
  #     questionnaires[round][:items].each do |item|
  #       Answer.create!(
  #         response_id: response.id,
  #         item_id: item.id,
  #         answer: rand(1..5),
  #         comments: "Seeded answer"
  #       )
  #     end
  #   end
  # end

  # ===================================================================
  # SEED DATA FOR JOIN TEAM REQUEST FUNCTIONALITY
  # ===================================================================
  begin
    puts "\n🔧 Creating seed data for join team request functionality..."

    # Get the 6 persistent students (alice, bob, charlie, diana, ethan, fiona)
    alice = User.find_by(name: 'alice')
    bob = User.find_by(name: 'bob')
    charlie = User.find_by(name: 'charlie')
    diana = User.find_by(name: 'diana')
    ethan = User.find_by(name: 'ethan')
    fiona = User.find_by(name: 'fiona')

    unless alice && bob && charlie && diana && ethan && fiona
      puts "⚠️  Warning: Not all test students found. Skipping join team request seeding."
      raise "Missing test students"
    end

    # Use the first existing assignment and update it for join team request testing
    assignment_with_topics = Assignment.first
    if assignment_with_topics
      assignment_with_topics.update!(
        has_topics: true,
        max_team_size: 4
      )
    else
      puts "⚠️  Warning: No assignments found. Skipping join team request seeding."
      raise "No assignments available"
    end
    puts "✅ Using assignment: #{assignment_with_topics.name} (ID: #{assignment_with_topics.id})"

    # Create sign-up topics for the assignment
    topics_data = [
      { topic_name: 'AI and Machine Learning', description: 'Research on artificial intelligence applications', max_choosers: 2 },
      { topic_name: 'Web Development', description: 'Modern web development frameworks and tools', max_choosers: 2 },
      { topic_name: 'Mobile Applications', description: 'iOS and Android app development', max_choosers: 2 }
    ]

    signup_topics = []
    topics_data.each do |topic_data|
      topic = SignUpTopic.find_or_create_by!(
        assignment_id: assignment_with_topics.id,
        topic_name: topic_data[:topic_name]
      ) do |t|
        t.description = topic_data[:description]
        t.max_choosers = topic_data[:max_choosers]
      end
      signup_topics << topic
      puts "✅ Created topic: #{topic.topic_name} (ID: #{topic.id})"
    end

    # Create assignment participants for all 6 students
    participants = {}
    [alice, bob, charlie, diana, ethan, fiona].each do |user|
    participant = AssignmentParticipant.find_or_create_by!(
      user_id: user.id,
      parent_id: assignment_with_topics.id
    ) do |p|
      p.handle = user.handle
      p.can_submit = true
      p.can_review = true
      p.type = 'AssignmentParticipant'
    end
    participants[user.name.to_sym] = participant
    puts "✅ Created participant for #{user.name} (ID: #{participant.id})"
  end

  # Create teams with topics
  # Team 1: Alice and Bob (AI and Machine Learning topic) - has advertisement
  team1 = AssignmentTeam.find_or_create_by!(
    name: 'AI Innovators',
    parent_id: assignment_with_topics.id
  ) do |t|
    t.type = 'AssignmentTeam'
  end

  # Add Alice and Bob to Team 1
  TeamsParticipant.find_or_create_by!(
    team_id: team1.id,
    participant_id: participants[:alice].id,
    user_id: alice.id
  )
  TeamsParticipant.find_or_create_by!(
    team_id: team1.id,
    participant_id: participants[:bob].id,
    user_id: bob.id
  )
  participants[:alice].update!(team_id: team1.id)
  participants[:bob].update!(team_id: team1.id)

  # Sign up Team 1 for AI topic
  signed_up_team1 = SignedUpTeam.find_or_create_by!(
    team_id: team1.id,
    sign_up_topic_id: signup_topics[0].id
  ) do |st|
    st.is_waitlisted = false
    st.advertise_for_partner = true
    st.comments_for_advertisement = 'Python &AND& TensorFlow &AND& Data Science'
  end
  puts "✅ Created Team 1: #{team1.name} with advertisement for #{signup_topics[0].topic_name}"

  # Team 2: Charlie (Web Development topic) - has advertisement, looking for teammates
  team2 = AssignmentTeam.find_or_create_by!(
    name: 'Web Warriors',
    parent_id: assignment_with_topics.id
  ) do |t|
    t.type = 'AssignmentTeam'
  end

  # Add Charlie to Team 2
  TeamsParticipant.find_or_create_by!(
    team_id: team2.id,
    participant_id: participants[:charlie].id,
    user_id: charlie.id
  )
  participants[:charlie].update!(team_id: team2.id)

  # Sign up Team 2 for Web Development topic
  signed_up_team2 = SignedUpTeam.find_or_create_by!(
    team_id: team2.id,
    sign_up_topic_id: signup_topics[1].id
  ) do |st|
    st.is_waitlisted = false
    st.advertise_for_partner = true
    st.comments_for_advertisement = 'React &AND& Node.js &AND& TypeScript'
  end
  puts "✅ Created Team 2: #{team2.name} with advertisement for #{signup_topics[1].topic_name}"

  # Team 3: Diana (Mobile Applications topic) - no advertisement yet
  team3 = AssignmentTeam.find_or_create_by!(
    name: 'Mobile Masters',
    parent_id: assignment_with_topics.id
  ) do |t|
    t.type = 'AssignmentTeam'
  end

  # Add Diana to Team 3
  TeamsParticipant.find_or_create_by!(
    team_id: team3.id,
    participant_id: participants[:diana].id,
    user_id: diana.id
  )
  participants[:diana].update!(team_id: team3.id)

  # Sign up Team 3 for Mobile Applications topic
  signed_up_team3 = SignedUpTeam.find_or_create_by!(
    team_id: team3.id,
    sign_up_topic_id: signup_topics[2].id
  ) do |st|
    st.is_waitlisted = false
    st.advertise_for_partner = false
  end
  puts "✅ Created Team 3: #{team3.name} for #{signup_topics[2].topic_name}"

  # Ethan and Fiona are NOT in teams yet (available to join teams)
  puts "✅ Ethan and Fiona are participants without teams (available to join)"

  # Create Join Team Requests
  # Request 1: Ethan wants to join Team 1 (AI Innovators) - PENDING
  join_request1 = JoinTeamRequest.find_or_create_by!(
    participant_id: participants[:ethan].id,
    team_id: team1.id
  ) do |jr|
    jr.comments = 'I have experience with Python and machine learning. Would love to contribute to the AI project!'
    jr.reply_status = 'PENDING'
  end
  puts "✅ Created join request: Ethan -> Team 1 (PENDING)"

  # Request 2: Fiona wants to join Team 2 (Web Warriors) - PENDING
  join_request2 = JoinTeamRequest.find_or_create_by!(
    participant_id: participants[:fiona].id,
    team_id: team2.id
  ) do |jr|
    jr.comments = 'I am proficient in React and Node.js. Can help with both frontend and backend!'
    jr.reply_status = 'PENDING'
  end
  puts "✅ Created join request: Fiona -> Team 2 (PENDING)"

  # Request 3: Ethan also wants to join Team 2 (alternative) - PENDING
  join_request3 = JoinTeamRequest.find_or_create_by!(
    participant_id: participants[:ethan].id,
    team_id: team2.id
  ) do |jr|
    jr.comments = 'Also interested in web development. Have full-stack experience.'
    jr.reply_status = 'PENDING'
  end
  puts "✅ Created join request: Ethan -> Team 2 (PENDING)"

  # Request 4: Fiona wants to join Team 3 (declined example)
  join_request4 = JoinTeamRequest.find_or_create_by!(
    participant_id: participants[:fiona].id,
    team_id: team3.id
  ) do |jr|
    jr.comments = 'Interested in mobile development!'
    jr.reply_status = 'DECLINED'
  end
  puts "✅ Created join request: Fiona -> Team 3 (DECLINED)"

    puts "\n✅ Join Team Request seed data created successfully!"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "Summary:"
    puts "  - Assignment: #{assignment_with_topics.name} (ID: #{assignment_with_topics.id})"
    puts "  - Topics: 3 (AI/ML, Web Dev, Mobile Apps)"
    puts "  - Teams with advertisements: 2 (Team 1, Team 2)"
    puts "  - Teams without advertisements: 1 (Team 3)"
    puts "  - Students in teams: Alice, Bob (Team 1), Charlie (Team 2), Diana (Team 3)"
    puts "  - Students without teams: Ethan, Fiona"
    puts "  - Join requests (PENDING): 3"
    puts "  - Join requests (DECLINED): 1"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  rescue => e
    puts "⚠️  Skipping join team request seeding due to: #{e.message}"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  end

rescue ActiveRecord::RecordInvalid => e
  puts "Seeding failed or the db is already seeded: #{e.message}"
end