# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Calibration API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:adm) {
    User.create(
      name: "adma",
      password_digest: "password",
      role_id: @roles[:admin].id,
      full_name: "Admin A",
      email: "instructor@example.com",
      mru_directory_path: "/home/testuser",
      )
  }

  let(:token) { JsonWebToken.encode({id: adm.id}) }
  let(:Authorization) { "Bearer #{token}" }

  path '/calibration/assignments/{assignment_id}/submissions' do
    parameter name: 'assignment_id', in: :path, type: :integer,
              description: 'ID of the assignment'

    get('get instructor calibration submissions') do
      tags 'Calibration'
      produces 'application/json'

      let(:instructor) { adm }

      let(:assignment) do
        Assignment.create!(
          name: 'Calibration Assignment',
          instructor_id: instructor.id
        )
      end

      let(:assignment_id) { assignment.id }

      # Instructor's participant record for this assignment
      let!(:instructor_participant) do
        Participant.create!(
          user_id: instructor.id,
          parent_id: assignment.id,
          type: 'AssignmentParticipant',
          handle: 'instructor_handle'
        )
      end

      # Reviewee team (reviewee_id is a Team ID)
      let!(:reviewee_team) do
        Team.create!(
          name: 'Team A',
          parent_id: assignment.id,
          type: 'AssignmentTeam'   # or whatever your app uses for assignment teams
        )
      end

      # Instructor's participant record for this assignment
      let!(:instructor_participant) do
        Participant.create!(
          user_id: instructor.id,
          parent_id: assignment.id,
          type: 'AssignmentParticipant',
          handle: 'instructor_handle'
        )
      end

      # ResponseMap where the INSTRUCTOR is the reviewer (for_calibration: true)
      let!(:response_map) do
        ResponseMap.create!(
          reviewer_id:        instructor_participant.id,
          reviewee_id:        reviewee_team.id,   # Team ID
          reviewed_object_id: assignment.id,
          for_calibration:    true
        )
      end

      # A submitted response so that get_review_status returns "completed"
      let!(:response_record) do
        Response.create!(
          map_id:       response_map.id,
          is_submitted: true
        )
      end

      # Stub submitted content for the team so the JSON is predictable
      before do
        allow_any_instance_of(CalibrationController).to receive(:get_submitted_content)
          .with(reviewee_team.id)
          .and_return({
            hyperlinks: ['https://example.com/report'],
            files: []
          })

        allow_any_instance_of(CalibrationController).to receive(:get_instructor_participant_id)
          .and_return(instructor_participant.id)
      end

      response(200, 'successful') do
        # rswag hook to capture an example response in the generated swagger
        after do |example|
          next unless response&.body.present?

          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |resp|
          body = JSON.parse(resp.body)

          expect(body['calibration_submissions']).to be_an(Array)
          expect(body['calibration_submissions'].size).to eq(1)

          submission = body['calibration_submissions'].first

          expect(submission['team_name']).to eq('Team A')
          expect(submission['reviewee_id']).to eq(reviewee_team.id)
          expect(submission['response_map_id']).to eq(response_map.id)
          expect(submission['submitted_content']['hyperlinks'])
            .to eq(['https://example.com/report'])
          expect(submission['review_status']).to eq('completed')
        end
      end
    end
  end


  path '/calibration/calibration_student_report' do
    parameter name: 'assignment_id', in: :query, type: :integer,
              description: 'ID of the assignment'
    parameter name: 'student_participant_id', in: :query, type: :integer,
              description: 'ID of the student participant'

    get 'get student calibration comparison' do
      tags 'Calibration'
      produces 'application/json'

      response(200, 'when both reviews exist') do
        let(:instructor) { adm }

        let(:assignment) do
          Assignment.create!(
            name: 'Calibration Assignment',
            instructor_id: instructor.id
          )
        end

        let(:assignment_id) { assignment.id }

        # Student participant (the reviewer)
        let(:student_user) do
          User.create!(
            name: 'student1',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Student One',
            email: 'student1@example.com',
            mru_directory_path: '/home/student1'
          )
        end

        let!(:student_participant) do
          Participant.create!(
            user_id: student_user.id,
            parent_id: assignment.id,
            type: 'AssignmentParticipant',
            handle: 'student_handle'
          )
        end

        let(:student_participant_id) { student_participant.id }

        # Team being reviewed (reviewee_id is a Team ID)
        # If your app uses AssignmentTeam < Team, replace with AssignmentTeam.create!
        let!(:reviewee_team) do
          Team.create!(
            name: 'Team A',
            parent_id: assignment.id,
            type: 'AssignmentTeam'   # or whatever your app uses for assignment teams
          )
        end

        # ResponseMap for the student's calibration review
        let!(:student_response_map) do
          ResponseMap.create!(
            reviewer_id:        student_participant.id,
            reviewee_id:        student_participant.id, # valid Participant for validation
            reviewed_object_id: assignment.id,
            for_calibration:    true
          ).tap do |rm|
            # Now point it at the Team ID, which is what the controller uses
            rm.update_column(:reviewee_id, reviewee_team.id)
          end
        end

        # ResponseMap where the INSTRUCTOR is the reviewer (for_calibration: true)
        let!(:instructor_response_map) do
          ResponseMap.create!(
            reviewer_id:        instructor_participant.id,
            reviewee_id:        instructor_participant.id, # valid Participant
            reviewed_object_id: assignment.id,
            for_calibration:    true
          ).tap do |rm|
            rm.update_column(:reviewee_id, reviewee_team.id)
          end
        end

        # Instructor's participant record for this assignment
        let!(:instructor_participant) do
          Participant.create!(
            user_id: instructor.id,
            parent_id: assignment.id,
            type: 'AssignmentParticipant',
            handle: 'instructor_handle'
          )
        end

        # Student's review (so student_review is not nil)
        let!(:student_review) do
          Response.create!(
            map_id:       student_response_map.id,
            is_submitted: true
          )
        end

        # Fake instructor review object (we don't care about its internals here)
        let!(:instructor_review) do
          Response.create!(
            map_id:       instructor_response_map.id,
            is_submitted: true
          )
        end

        # Stub helper methods so we don't need to set up Answers/Questionnaire
        before do
          allow_any_instance_of(CalibrationController).to receive(:get_instructor_review_for_reviewee)
            .and_return(instructor_review)

          allow_any_instance_of(CalibrationController).to receive(:instructor_review_better?)
            .and_return({
              agreement_percentage: 100.0,
              questions: []
            })
        end

        # Capture example for Swagger
        after do |example|
          # If the request never actually ran (e.g., setup error), response will be nil
          next unless response&.body.present?

          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        
        run_test! do |resp|
          body = JSON.parse(resp.body)

          expect(body['calibration_reviews']).to be_an(Array)
          expect(body['calibration_reviews'].size).to eq(1)
          first = body['calibration_reviews'].first

          expect(first['reviewee_name']).to eq('Team A')
          expect(first['reviewee_id']).to eq(reviewee_team.id)
          expect(first['comparison']['agreement_percentage']).to eq(100.0)
        end
      end

      response(200, 'when review data is missing') do
        let(:instructor) { adm }

        let(:assignment) do
          Assignment.create!(
            name: 'Calibration Assignment',
            instructor_id: instructor.id
          )
        end

        let(:assignment_id) { assignment.id }

        let(:student_user) do
          User.create!(
            name: 'student2',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Student Two',
            email: 'student2@example.com',
            mru_directory_path: '/home/student2'
          )
        end

        let!(:student_participant) do
          Participant.create!(
            user_id: student_user.id,
            parent_id: assignment.id,
            type: 'AssignmentParticipant',
            handle: 'student_handle'
          )
        end

        let(:student_participant_id) { student_participant.id }

        let!(:reviewee_team) do
          Team.create!(
            name: 'Team B',
            parent_id: assignment.id,
            type: 'AssignmentTeam'   # or whatever your app uses for assignment teams
          )
        end

        let!(:student_response_map) do
          ResponseMap.create!(
            reviewer_id:        student_participant.id,
            reviewee_id:        student_participant.id,
            reviewed_object_id: assignment.id,
            for_calibration:    true
          ).tap do |rm|
            rm.update_column(:reviewee_id, reviewee_team.id)
          end
        end

        # NOTE: no Response created for the student → student_review will be nil

        # Also stub instructor review as nil to force the error branch
        before do
          allow_any_instance_of(CalibrationController).to receive(:get_instructor_review_for_reviewee)
            .and_return(nil)
        end

        run_test! do |resp|
          body = JSON.parse(resp.body)

          expect(body['calibration_reviews']).to be_an(Array)
          expect(body['calibration_reviews'].size).to eq(1)

          comparison = body['calibration_reviews'].first
          expect(comparison['reviewee_name']).to eq('Team B')

          comparison_hash = comparison['comparison']
          expect(comparison_hash['error']).to eq('Missing review data')
        end
      end

      response(200, 'when there are no calibration maps') do
        let(:instructor) { adm }

        let(:assignment) do
          Assignment.create!(
            name: 'Calibration Assignment',
            instructor_id: instructor.id
          )
        end

        let(:assignment_id) { assignment.id }

        let(:student_user) do
          User.create!(
            name: 'student3',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Student Three',
            email: 'student3@example.com',
            mru_directory_path: '/home/student3'
          )
        end

        let!(:student_participant) do
          Participant.create!(
            user_id: student_user.id,
            parent_id: assignment.id,
            type: 'AssignmentParticipant',
            handle: 'student_handle'
          )
        end

        let(:student_participant_id) { student_participant.id }

        # NOTE: no ResponseMap created at all

        run_test! do |resp|
          body = JSON.parse(resp.body)
          expect(body['calibration_reviews']).to eq([])
        end
      end
    end
  end

  path '/calibration/assignments/{assignment_id}/students/{student_participant_id}/summary' do
    parameter name: 'assignment_id', in: :path, type: :integer,
              description: 'ID of the assignment'
    parameter name: 'student_participant_id', in: :path, type: :integer,
              description: 'ID of the student participant'

    get 'get calibration summary' do
      tags 'Calibration'
      produces 'application/json'

      response(200, 'when everything is working') do
        let(:instructor) { adm }

        let(:assignment) do
          Assignment.create!(
            name: 'Calibration Assignment (summary)',
            instructor_id: instructor.id
          )
        end

        let(:assignment_id) { assignment.id }

        # Student participant (the reviewer)
        let(:student_user) do
          User.create!(
            name: 'student_summary_1',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Student Summary One',
            email: 'student_summary1@example.com',
            mru_directory_path: '/home/student_summary1'
          )
        end

        let!(:student_participant) do
          Participant.create!(
            user_id: student_user.id,
            parent_id: assignment.id,
            type: 'AssignmentParticipant',
            handle: 'student_handle'
          )
        end

        let(:student_participant_id) { student_participant.id }

        # Team being reviewed (reviewee_team_id)
        let!(:reviewee_team) do
        Team.create!(
          name: 'Summary Team A',
          parent_id: assignment.id,
          type: 'AssignmentTeam'   # or whatever your app uses for assignment teams
        )
      end

        # Team members (participants on this team)
        let!(:team_member_user1) do
          User.create!(
            name: 'member1',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Member One',
            email: 'member1@example.com',
            mru_directory_path: '/home/member1'
          )
        end

        let!(:team_member_user2) do
          User.create!(
            name: 'member2',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Member Two',
            email: 'member2@example.com',
            mru_directory_path: '/home/member2'
          )
        end

        let!(:team_member1) do
          Participant.create!(
            user_id:  team_member_user1.id,
            parent_id: reviewee_team.id,      # treat team as the parent in this context
            type:     'AssignmentParticipant',
            handle:   'member_one'
          )
        end

        let!(:team_member2) do
          Participant.create!(
            user_id:  team_member_user2.id,
            parent_id: reviewee_team.id,
            type:     'AssignmentParticipant',
            handle:   'member_two'
          )
        end

        # ResponseMap for this student’s calibration review
        let!(:student_response_map) do
          ReviewResponseMap.create!(
            reviewer_id:        student_participant.id,
            reviewee_id:        reviewee_team.id,
            reviewed_object_id: assignment.id,
            for_calibration:    true
          )
        end

        # Stub submitted content so hyperlinks are deterministic
        before do
          allow_any_instance_of(CalibrationController).to receive(:get_submitted_content)
            .with(reviewee_team.id)
            .and_return({
              hyperlinks: ['https://example.com/artifact1'],
              files: []
            })
        end

        # Capture example JSON in Swagger
        # Inside the `response(200, 'when everything is working') do ... end` block
        after do |example|
          # If the request never ran (setup error), response will be nil
          next unless response&.body.present?

          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |resp|
          body = JSON.parse(resp.body)

          expect(body['student_participant_id']).to eq(student_participant_id.to_s).or eq(student_participant_id)
          expect(body['assignment_id']).to eq(assignment_id.to_s).or eq(assignment_id)
          expect(body['submissions']).to be_an(Array)
          expect(body['submissions'].size).to eq(1)

          submission = body['submissions'].first
          expect(submission['reviewee_team_id']).to eq(reviewee_team.id)
          expect(submission['for_calibration']).to eq(true)

          reviewer_names = submission['reviewers'].map { |r| r['full_name'] }
          expect(reviewer_names).to match_array(['Member One', 'Member Two'])

          expect(submission['hyperlinks']).to eq(['https://example.com/artifact1'])
        end
      end

      response(404, 'when student or assignment does not exist') do
        # Use IDs that don't exist in the DB
        let(:assignment_id) { 999_999 }
        let(:student_participant_id) { 888_888 }

        run_test! do |resp|
          expect(resp.status).to eq(404)
          body = JSON.parse(resp.body)
          expect(body['error']).to eq('Assignment or student not found')
        end
      end

      response(200, 'when there are no hyperlinks for a submission') do
        let(:instructor) { adm }

        let(:assignment) do
          Assignment.create!(
            name: 'Calibration Assignment (no links)',
            instructor_id: instructor.id
          )
        end

        let(:assignment_id) { assignment.id }

        let(:student_user) do
          User.create!(
            name: 'student_summary_2',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Student Summary Two',
            email: 'student_summary2@example.com',
            mru_directory_path: '/home/student_summary2'
          )
        end

        let!(:student_participant) do
          Participant.create!(
            user_id: student_user.id,
            parent_id: assignment.id,
            type: 'AssignmentParticipant',
            handle: 'student_handle'
          )
        end

        let(:student_participant_id) { student_participant.id }

        let!(:reviewee_team) do
        Team.create!(
          name: 'Summary Team B',
          parent_id: assignment.id,
          type: 'AssignmentTeam'   # or whatever your app uses for assignment teams
        )
      end

        let!(:team_member_user) do
          User.create!(
            name: 'member_only',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Solo Member',
            email: 'member_only@example.com',
            mru_directory_path: '/home/member_only'
          )
        end

        let!(:team_member) do
          Participant.create!(
            user_id:  team_member_user.id,
            parent_id: reviewee_team.id,
            type:     'AssignmentParticipant',
            handle:   'solo_member'
          )
        end

        let!(:student_response_map) do
          ReviewResponseMap.create!(
            reviewer_id:        student_participant.id,
            reviewee_id:        reviewee_team.id,
            reviewed_object_id: assignment.id,
            for_calibration:    true
          )
        end

        before do
          # No hyperlinks; controller should output []
          allow_any_instance_of(CalibrationController).to receive(:get_submitted_content)
            .with(reviewee_team.id)
            .and_return({
              hyperlinks: [],
              files: []
            })
        end

        run_test! do |resp|
          body = JSON.parse(resp.body)

          expect(body['submissions']).to be_an(Array)
          expect(body['submissions'].size).to eq(1)

          submission = body['submissions'].first
          expect(submission['reviewee_team_id']).to eq(reviewee_team.id)
          expect(submission['hyperlinks']).to eq([]) # allowed
        end
      end
    end
  end

  path '/calibration/assignments/{assignment_id}/report/{reviewee_id}' do
    parameter name: 'assignment_id', in: :path, type: :integer,
              description: 'ID of the assignment'
    parameter name: 'reviewee_id', in: :path, type: :integer,
              description: 'Team ID of the reviewee'

    get 'get calibration aggregate report' do
      tags 'Calibration'
      produces 'application/json'

      response(200, 'when report is generated successfully') do
        let(:instructor) { adm }

        let(:assignment) do
          Assignment.create!(
            name: 'Calibration Assignment (aggregate)',
            instructor_id: instructor.id
          )
        end

        let(:assignment_id) { assignment.id }

        # Reviewee team (reviewee_id is a Team ID)
        let!(:reviewee_team) do
          Team.create!(
            name: '',                          # force fallback to participant.user.full_name
            parent_id: assignment.id,
            type: 'AssignmentTeam'
          )
        end

        let(:reviewee_id) { reviewee_team.id }

        # Team member used to derive reviewee_name
        let!(:reviewee_user) do
          User.create!(
            name: 'reviewee_user',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Reviewee User',
            email: 'reviewee@example.com',
            mru_directory_path: '/home/reviewee'
          )
        end

        let!(:reviewee_participant) do
          Participant.create!(
            user_id:  reviewee_user.id,
            parent_id: reviewee_team.id,      # makes reviewee_team.participants work
            type:     'AssignmentParticipant',
            handle:   'reviewee_participant'
          )
        end

        # Instructor's participant record for this assignment
        let!(:instructor_participant) do
          Participant.create!(
            user_id: instructor.id,
            parent_id: assignment.id,
            type: 'AssignmentParticipant',
            handle: 'instructor_handle'
          )
        end

        # ResponseMap where the INSTRUCTOR is the reviewer (for_calibration: true)
        let!(:instructor_response_map) do
          ReviewResponseMap.create!(
            reviewer_id:        instructor_participant.id,
            reviewee_id:        reviewee_team.id,
            reviewed_object_id: assignment.id,
            for_calibration:    true
          )
        end

        # Instructor review we will feed into the report
        let!(:instructor_review) do
          Response.create!(
            map_id:       instructor_response_map.id,
            is_submitted: true
          )
        end

        let!(:questionnaire) do
          instructor
          Questionnaire.create(
            name: 'Questionnaire 1',
            questionnaire_type: 'AuthorFeedbackReview',
            private: true,
            min_question_score: 0,
            max_question_score: 10,
            instructor_id: instructor.id
          )
        end

        let!(:item) do
          Item.create(
            seq: 1, 
            txt: "test item 1",
            question_type: "multiple_choice", 
            break_before: true, 
            weight: 5,
            questionnaire: questionnaire
          )
        end

        # Instructor's answers: one question with item_id 1, score 5
        let!(:instructor_answer) do
          Answer.create!(
            response_id: instructor_review.id,
            item_id: item.id,
            answer: 5
          )
        end

        # Student who did a calibration review
        let!(:student_user) do
          User.create!(
            name: 'student_agg',
            password_digest: 'password',
            role_id: @roles[:student].id,
            full_name: 'Student Agg',
            email: 'student_agg@example.com',
            mru_directory_path: '/home/student_agg'
          )
        end

        let!(:student_participant) do
          Participant.create!(
            user_id: student_user.id,
            parent_id: assignment.id,
            type: 'AssignmentParticipant',
            handle: 'student_handle'
          )
        end

        # Student calibration map for this assignment + reviewee team
        let!(:student_map) do
          ReviewResponseMap.create!(
            reviewer_id:        student_participant.id,
            reviewee_id:        reviewee_team.id,
            reviewed_object_id: assignment.id,
            for_calibration:    true
          )
        end

        # Latest student response for that map
        let!(:student_response) do
          Response.create!(
            map_id:       student_map.id,
            is_submitted: true
          )
        end

        # Student answer for same item_id 1, also score 5 (perfect match)
        let!(:student_answer) do
          Answer.create!(
            response_id: student_response.id,
            item_id:     1,
            answer:      5
          )
        end

        before do
          # Stub helper methods so we don't depend on their internal queries
          allow_any_instance_of(CalibrationController).to receive(:get_instructor_review_for_reviewee)
            .and_return(instructor_review)

          # We don't care what this returns as long as it's NOT the student reviewer_id
          allow_any_instance_of(CalibrationController).to receive(:get_instructor_participant_id)
            .and_return(instructor_participant.id)
        end

        # Capture example JSON for Swagger UI
        after do |example|
          next unless response&.body.present?

          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end

        run_test! do |resp|
          body = JSON.parse(resp.body)

          expect(body['assignment_id']).to eq(assignment_id.to_s).or eq(assignment_id)
          expect(body['reviewee_id']).to eq(reviewee_id.to_s).or eq(reviewee_id)
          expect(body['reviewee_name']).to eq('Reviewee User')

          stats = body['aggregate_stats']
          expect(stats['total_reviews']).to eq(1)
          expect(stats['avg_agreement_percentage']).to eq(100.0)

          qb = stats['question_breakdown']
          expect(qb).to be_an(Array)
          expect(qb.size).to eq(1)

          q1 = qb.first
          expect(q1['item_id']).to eq(1)
          expect(q1['instructor_score']).to eq(5)
          expect(q1['avg_student_score']).to eq(5.0)
          expect(q1['match_rate']).to eq(100.0)
        end
      end

      response(404, 'when instructor review is missing') do
        let(:instructor) { adm }

        let(:assignment) do
          Assignment.create!(
            name: 'Calibration Assignment (no instructor review)',
            instructor_id: instructor.id
          )
        end

        let(:assignment_id) { assignment.id }

        let!(:reviewee_team) do
          Team.create!(
            name: 'Team Without Instructor Review',
            parent_id: assignment.id,
            type: 'AssignmentTeam'   # or whatever your app uses for assignment teams
          )
        end

        let(:reviewee_id) { reviewee_team.id }

        before do
          allow_any_instance_of(CalibrationController).to receive(:get_instructor_review_for_reviewee)
            .and_return(nil)
        end

        run_test! do |resp|
          expect(resp.status).to eq(404)
          body = JSON.parse(resp.body)
          expect(body['error']).to eq('Instructor review not found. Cannot generate report.')
        end
      end
    end
  end
end