# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Responses API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_resp",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Resp",
      email: "instructor_resp@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name: "student_resp",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student Resp",
      email: "student_resp@example.com"
    )
  end

  let(:token) { JsonWebToken.encode({ id: student.id }) }
  let(:Authorization) { "Bearer #{token}" }

  let!(:assignment) do
    Assignment.create!(
      name: "Resp Assignment",
      instructor: instructor
    )
  end

  let!(:reviewer_participant) do
    AssignmentParticipant.create!(
      user_id: student.id,
      parent_id: assignment.id,
      handle: student.name
    )
  end

  let!(:reviewee_participant) do
    AssignmentParticipant.create!(
      user_id: instructor.id,
      parent_id: assignment.id,
      handle: instructor.name
    )
  end

  let!(:team) do
    AssignmentTeam.create!(
      name: "Resp Team",
      parent_id: assignment.id
    )
  end

  let!(:teams_participant) do
    TeamsParticipant.create!(
      team: team,
      participant: reviewer_participant,
      user: student
    )
  end

  let!(:review_map) do
    map = ReviewResponseMap.new(
      reviewer_id: reviewer_participant.id,
      reviewee_id: reviewee_participant.id,
      reviewed_object_id: assignment.id
    )
    map.save!(validate: false)
    map
  end

  let!(:response_record) do
    Response.create!(
      map_id: review_map.id,
      round: 1,
      is_submitted: false,
      additional_comment: "Initial comment"
    )
  end

  # -------------------------------------------------------------------------
  # POST /responses
  # -------------------------------------------------------------------------
  path '/responses' do
    post 'Create a response' do
      tags 'Responses'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          response_map_id: { type: :integer },
          round: { type: :integer },
          content: { type: :string }
        },
        required: ['response_map_id']
      }

      response '201', 'response created successfully' do
        let(:body) do
          {
            response_map_id: review_map.id,
            round: 1,
            content: '{}'
          }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['map_id']).to eq(review_map.id)
          expect(data['round']).to eq(1)
        end
      end

      response '201', 'allows create when all prior tasks are complete' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "Resp Quiz Prior",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end
        let(:body) { { response_map_id: review_map.id, round: 1, content: '{}' } }

        before do
          allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
          quiz_map = QuizResponseMap.new(
            reviewer_id: reviewer_participant.id,
            reviewee_id: reviewee_participant.id,
            reviewed_object_id: assignment.id
          )
          quiz_map.save!(validate: false)
          Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)
        end

        run_test! do |response|
          expect([201, 200]).to include(response.status)
        end
      end

      response '403', 'blocks create when prior quiz task is not complete' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "Resp Quiz Block",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end
        let(:body) { { response_map_id: review_map.id, round: 1, content: '{}' } }

        before do
          allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
          # Quiz map exists but response is NOT submitted
          quiz_map = QuizResponseMap.new(
            reviewer_id: reviewer_participant.id,
            reviewee_id: reviewee_participant.id,
            reviewed_object_id: assignment.id
          )
          quiz_map.save!(validate: false)
          Response.create!(map_id: quiz_map.id, round: 1, is_submitted: false)
        end

        run_test! do |response|
          expect([403]).to include(response.status)
        end
      end

      response '404', 'response map not found' do
        let(:body) { { response_map_id: 99999, round: 1 } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to include('not found')
        end
      end

      response '403', 'unauthorized reviewer' do
        let!(:other_student) do
          User.create!(
            name: "other_resp",
            password_digest: "password",
            role_id: @roles[:student].id,
            full_name: "Other Resp",
            email: "other_resp@example.com"
          )
        end
        let(:token) { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:body) { { response_map_id: review_map.id, round: 1 } }

        run_test! do |response|
          expect([403, 404]).to include(response.status)
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:body) { { response_map_id: review_map.id, round: 1 } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Not Authorized")
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # GET /responses/:id
  # -------------------------------------------------------------------------
  path '/responses/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'ID of the response'
    parameter name: 'Authorization', in: :header, type: :string

    get 'Show a response' do
      tags 'Responses'
      produces 'application/json'

      response '200', 'response found' do
        let(:id) { response_record.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['response_id']).to eq(response_record.id)
          expect(data['map_id']).to eq(review_map.id)
          expect(data['submitted']).to be false
        end
      end

      response '404', 'response not found' do
        let(:id) { 99999 }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:id) { response_record.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Not Authorized")
        end
      end
    end

    # -------------------------------------------------------------------------
    # PATCH /responses/:id
    # -------------------------------------------------------------------------
    patch 'Update a response' do
      tags 'Responses'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          is_submitted: { type: :boolean },
          additional_comment: { type: :string }
        }
      }

      response '200', 'response updated successfully' do
        let(:id) { response_record.id }
        let(:body) { { is_submitted: true } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['submitted']).to be true
        end
      end

      response '200', 'allows submit/update when prior tasks are complete' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "Resp Quiz Upd",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end
        let(:id) { response_record.id }
        let(:body) { { is_submitted: true } }

        before do
          allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
          quiz_map = QuizResponseMap.new(
            reviewer_id: reviewer_participant.id,
            reviewee_id: reviewee_participant.id,
            reviewed_object_id: assignment.id
          )
          quiz_map.save!(validate: false)
          Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)
        end

        run_test! do |response|
          expect([200]).to include(response.status)
          data = JSON.parse(response.body)
          expect(data['submitted']).to be true
        end
      end

      response '403', 'blocks submit/update when prior quiz task is incomplete' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "Resp Quiz BlkUpd",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end
        let(:id) { response_record.id }
        let(:body) { { is_submitted: true } }

        before do
          allow(assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
          quiz_map = QuizResponseMap.new(
            reviewer_id: reviewer_participant.id,
            reviewee_id: reviewee_participant.id,
            reviewed_object_id: assignment.id
          )
          quiz_map.save!(validate: false)
          # Quiz response exists but not submitted
          Response.create!(map_id: quiz_map.id, round: 1, is_submitted: false)
        end

        run_test! do |response|
          expect([403]).to include(response.status)
        end
      end

      response '403', 'not authorized to update response' do
        let!(:other_student) do
          User.create!(
            name: "other_upd",
            password_digest: "password",
            role_id: @roles[:student].id,
            full_name: "Other Upd",
            email: "other_upd@example.com"
          )
        end
        let(:token) { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:id) { response_record.id }
        let(:body) { { is_submitted: true } }

        run_test! do |response|
          expect([403, 404]).to include(response.status)
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:id) { response_record.id }
        let(:body) { { is_submitted: true } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Not Authorized")
        end
      end
    end
  end
end