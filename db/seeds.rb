begin
    #Create an institution
    inst_id = Institution.create!(
      name: 'North Carolina State University',
    ).id
    
    roles = {
      admin: Role.find_or_create_by!(name: 'Super Administrator'),
      instructor: Role.find_or_create_by!(name: 'Instructor'),
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


    assignment_ids = [1, 2]
    used_in_rounds = [1, 2]
    questionnaire_id = 1

    assignment_ids.each do |assignment_id|
      used_in_rounds.each do |round|
        AssignmentQuestionnaire.create!(
          assignment_id: assignment_id,
          questionnaire_id: questionnaire_id,
          used_in_round: round
        )
        questionnaire_id += 1
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

  questionnaires = {}

  (1..2).each do |round|
    questionnaire = Questionnaire.create!(
      name: "Review Rubric - Round #{round}",
      max_question_score: 5,
      min_question_score: 0,
      questionnaire_type: "ReviewQuestionnaire",
      display_type: "Review",
      instructor_id: 2,
      private: false
    )

    # Save questionnaire and its items
    questionnaires[round] = {
      q: questionnaire,
      items: []
    }

    5.times do |i|
      item = Item.create!(
        txt: Faker::Lorem.sentence(word_count: 8),
        weight: rand(1..2),
        seq: i + 1,
        question_type: ['Criterion', 'Scale', 'TextArea', 'Dropdown'].sample,
        size: ['50x3', '60x4', '40x2'].sample,
        alternatives: 'Yes|No',
        break_before: true,
        max_label: Faker::Lorem.word.capitalize,
        min_label: Faker::Lorem.word.capitalize,
        questionnaire_id: questionnaire.id
      )
      questionnaires[round][:items] << item
    end
  end

  # Create team and reviewers
  team = AssignmentTeam.find(1)

  3.times do |i|
    reviewer = AssignmentParticipant.find(i + 1)

    map = ReviewResponseMap.create!(
      reviewer_id: reviewer.id,
      reviewee_id: team.id,
      reviewed_object_id: 1 # optional if used for navigation only
    )

    [1, 2].each do |round|
      response = Response.create!(
        map_id: map.id,
        round: round,
        is_submitted: true
      )

      # Get the correct items for this round
      questionnaires[round][:items].each do |item|
        Answer.create!(
          response_id: response.id,
          item_id: item.id,
          answer: rand(1..5),
          comments: "Seeded answer"
        )
      end
    end
  end

rescue ActiveRecord::RecordInvalid => e
  puts "Seeding failed or the db is already seeded: #{e.message}"
end