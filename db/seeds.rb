# frozen_string_literal: true

# FactoryBot is required for the new E2562 seeding logic, but we use direct model creation instead of FactoryBot.create
require 'factory_bot_rails'

begin
    #Create an instritution
    inst_id = Institution.create!(
        name: 'North Carolina State University',
    ).id

    roles = {}

    roles[:super_admin] = Role.find_or_create_by!(name: "Super Administrator", parent_id: nil)

    roles[:admin] = Role.find_or_create_by!(name: "Administrator", parent_id: roles[:super_admin].id)

    roles[:instructor] = Role.find_or_create_by!(name: "Instructor", parent_id: roles[:admin].id)

    roles[:ta] = Role.find_or_create_by!(name: "Teaching Assistant", parent_id: roles[:instructor].id)

    roles[:student] = Role.find_or_create_by!(name: "Student", parent_id: roles[:ta].id)

    puts "reached here"
    # Create an admin user
    User.create!(
        name: 'admin',
        email: 'admin2@example.com',
        password: 'password123',
        full_name: 'admin admin',
        institution_id: inst_id,
        role_id: roles[:super_admin].id
    )

    # Create test student users student1..student5 for easy testing
    (1..5).each do |i|
        created_student = User.create!(
            name: "student#{i}",
            email: "student#{i}@test.com",
            password: 'password123',
            full_name: "Student #{i}",
            institution_id: inst_id,
            role_id: roles[:student].id
        )
        puts "Created test student: #{created_student.email} with password: password123"
    end


    #Generate Random Users
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
            institution_id: inst_id,
            role_id: roles[:instructor].id
            # Removed: type: 'Instructor'
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
            course_id: course_ids[i%num_courses],
            has_teams: true,
            private: false
        ).id
    end


    puts "creating teams"
    team_ids = []
    num_teams.times do |i|
        team_ids << AssignmentTeam.create(
            name: "Team #{i + 1}",
            parent_id: assignment_ids[i%num_assignments],
            type: 'AssignmentTeam' # This still needs 'type' for STI on the Team model
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
            institution_id: inst_id,
            role_id: roles[:student].id
            # Removed: type: 'Student'
        ).id
    end

    puts "assigning students to teams (TeamsParticipant)"
    teams_participant_ids = []
    num_students.times do |i|
        team_id = team_ids[i % num_teams]
        user_id = student_user_ids[i]
        
        # Participant must exist with the correct type before creating TeamsParticipant
        participant = AssignmentParticipant.find_or_create_by!(user_id: user_id, parent_id: assignment_ids[i%num_assignments]) do |p|
          p.team_id = team_id
          p.type = 'AssignmentParticipant' # This still needs 'type' for STI on the Participant model
        end

        tp = TeamsParticipant.create(
            team_id: team_id,
            user_id: user_id,
            participant_id: participant.id
        )
        if tp.persisted?
            teams_participant_ids << tp.id
        else
            puts "Failed to create TeamsParticipant: #{tp.errors.full_messages.join(', ')}"
        end
    end

    puts "assigning participant to students, teams, courses, and assignments"
    participant_ids = []
    num_students.times do |i|
        participant_ids << AssignmentParticipant.find_or_create_by!(
            user_id: student_user_ids[i],
            parent_id: assignment_ids[i%num_assignments],
            team_id: team_ids[i%num_teams]
        ) do |p|
            p.type = 'AssignmentParticipant' # This still needs 'type' for STI on the Participant model
        end.id
    end

    puts "creating project topics for testing"
    if assignment_ids.any?
        # Generate random topics for each assignment
        assignment_ids.each do |assignment_id|
            num_topics = rand(3..6)
            
            num_topics.times do |i|
                # Ensure topic_identifier within 10 chars limit
                identifier = "T" + Faker::Alphanumeric.alphanumeric(number: 5).upcase
                ProjectTopic.create!(
                    topic_identifier: identifier,
                    topic_name: Faker::Educator.course_name,
                    category: Faker::Book.genre,
                    max_choosers: rand(2..5),
                    description: Faker::Lorem.sentence(word_count: 10),
                    link: Faker::Internet.url,
                    assignment_id: assignment_id
                )
            end
            puts "Created #{num_topics} topics for assignment #{assignment_id}"
        end
    end

    # -----------------------------------------------------------------------------
    # --- START: E2562 Review Grading Dashboard Seeding (Fixed for User model) -----
    # -----------------------------------------------------------------------------
    puts "\n--- Seeding data for E2562. Review grading dashboard ---"

    # 1. Create a dedicated Instructor (FIXED: Removed u.type = 'Instructor')
    instructor = User.find_or_create_by!(name: 'instructor99') do |u|
        u.email = 'instructor99@expertiza.edu'
        u.password = 'password123'
        u.full_name = 'E2562 Coordinator'
        u.institution_id = inst_id
        u.role_id = roles[:instructor].id
    end

    # 2. Create the E2562 Assignment
    assignment = Assignment.find_or_create_by!(name: 'E2562_Review_Dashboard', instructor: instructor) do |a|
        a.has_teams = true
    end

    # 3. Create a Review Questionnaire
    puts "Seeding Review Questionnaire..."
    review_questionnaire = Questionnaire.find_or_create_by!(name: 'Review Rubric', type: 'ReviewQuestionnaire') do |q|
        q.max_question_score = 5
        q.min_question_score = 1
        q.instructor_id = instructor.id
    end
    
    created_questions = []

    # 4. Add questions to the questionnaire (Scale and Text Area)
    created_questions << Scale.find_or_create_by!(questionnaire_id: review_questionnaire.id, txt: 'Technical merit (1-5)') do |q|
        q.weight = 3
        q.type = 'Scale'
    end
    created_questions << TextArea.find_or_create_by!(questionnaire_id: review_questionnaire.id, txt: 'General Comments (Volume Metric)') do |q|
        q.weight = 1
        q.type = 'TextArea'
    end

    # 5. Link the questionnaire to the assignment
    AssignmentQuestionnaire.find_or_create_by!(assignment: assignment, questionnaire: review_questionnaire, used_in_round: 1)

    # --- 6. Create Teams and Participants -----------------------------------------
    # Create Student Reviewers (FIXED: Removed u.type = 'Student')
    num_reviewers = 4
    reviewers = []
    (1..num_reviewers).each do |i|
        reviewers << User.find_or_create_by!(name: "e2562_reviewer_#{i}") do |u|
            u.email = "e2562_reviewer_#{i}@expertiza.edu"
            u.password = 'password123'
            u.full_name = "E2562 Reviewer #{i}"
            u.institution_id = inst_id
            u.role_id = roles[:student].id
        end
    end

    # Create a Team to be Reviewed
    team_to_be_reviewed = AssignmentTeam.find_or_create_by!(name: 'Target_Team_X', parent_id: assignment.id) do |t|
        t.type = 'AssignmentTeam'
    end

    # Create Participants for the assignment
    reviewer_participants = reviewers.map do |user|
        AssignmentParticipant.find_or_create_by!(assignment: assignment, user: user) do |p|
            p.type = 'AssignmentParticipant'
        end
    end

    # --- 7. Create Reviews (ResponseMaps, Responses, Answers) ---------------------
    puts "Creating Reviews (Responses)..."

    review_statuses = [
        { is_submitted: true, round: 1, comment: 'Excellent and thorough review. Very detailed comments on the architecture.' }, 
        { is_submitted: true, round: 1, comment: 'Good review. Needs more technical depth.' }, 
        { is_submitted: false, round: 1, comment: nil }, 
        { is_submitted: true, round: 1, comment: 'Solid review. Just a few words.' }
    ]

    scale_question = created_questions.find { |q| q.type == 'Scale' }
    text_area_question = created_questions.find { |q| q.type == 'TextArea' }

    reviewer_participants.each_with_index do |reviewer_participant, index|
        status = review_statuses[index]

        # Create a ReviewResponseMap
        review_map = ReviewResponseMap.find_or_create_by!(
            reviewed_object_id: assignment.id, 
            reviewer_id: reviewer_participant.id,
            reviewee_id: team_to_be_reviewed.id,
            type: 'ReviewResponseMap'
        )

        # Create a Response for the map
        if status[:is_submitted]
            response = Response.find_or_create_by!(map_id: review_map.id, round: 1) do |r|
                r.is_submitted = true
            end

            # Create Answers for the Response
            if scale_question
                Answer.find_or_create_by!(response_id: response.id, question_id: scale_question.id) do |a|
                    a.answer = rand(3..scale_question.max_question_score)
                end
            end
            
            if text_area_question
                Answer.find_or_create_by!(response_id: response.id, question_id: text_area_question.id) do |a|
                    a.comments = status[:comment]
                end
            end
        end
    end

    puts "Seeding complete. Created #{num_reviewers} reviews for Team: #{team_to_be_reviewed.name}"
    # -----------------------------------------------------------------------------
    # --- END: E2562 Review Grading Dashboard Seeding ------------------------------
    # -----------------------------------------------------------------------------

rescue ActiveRecord::RecordInvalid => e
    puts e.message
    puts 'The db has already been seeded'
end