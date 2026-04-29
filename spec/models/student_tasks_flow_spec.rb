# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'StudentTasks Flow API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_flow",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Flow",
      email: "instructor_flow@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name: "student_flow",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student Flow",
      email: "student_flow@example.com"
    )
  end

  let(:token) { JsonWebToken.encode({ id: student.id }) }
  let(:Authorization) { "Bearer #{token}" }

  let!(:assignment) do
    Assignment.create!(name: "Flow Assignment", instructor: instructor)
  end

  let!(:participant) do
    AssignmentParticipant.create!(
      user_id: student.id,
      parent_id: assignment.id,
      handle: student.name
    )
  end

  let!(:team) do
    AssignmentTeam.create!(name: "Flow Team", parent_id: assignment.id)
  end

  let!(:teams_participant) do
    TeamsParticipant.create!(team: team, participant: participant, user: student)
  end

  let!(:review_map) do
    map = ReviewResponseMap.new(
      reviewer_id: participant.id,
      reviewee_id: participant.id,
      reviewed_object_id: assignment.id
    )
    map.save!(validate: false)
    map
  end

  # ---------------------------------------------------------------------------
  # GET /student_tasks/queue
  # ---------------------------------------------------------------------------
  path '/student_tasks/queue' do
    get 'Get task queue for an assignment' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'assignment_id', in: :query, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'returns review-only queue when no quiz questionnaire' do
        before { allow_any_instance_of(Assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          task_types = data.map { |t| t['task_type'] }
          expect(task_types).not_to include('quiz')
          expect(task_types).to include('review')
        end
      end

      response '200', 'returns quiz task before review task when both available' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "Flow Quiz Q",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end
        before { allow_any_instance_of(Assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          task_types = data.map { |t| t['task_type'] }
          quiz_index   = task_types.index('quiz')
          review_index = task_types.index('review')
          if quiz_index && review_index
            expect(quiz_index).to be < review_index
          end
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 99999 }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not Authorized')
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /student_tasks/next_task
  # ---------------------------------------------------------------------------
  path '/student_tasks/next_task' do
    get 'Get the next incomplete task for an assignment' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'assignment_id', in: :query, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'returns first incomplete task when tasks exist' do
        before { allow_any_instance_of(Assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('task_type')
        end
      end

      response '200', 'returns all tasks completed message when all submitted' do
        before do
          allow_any_instance_of(Assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil)
          Response.create!(map_id: review_map.id, round: 1, is_submitted: true)
        end
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('All tasks completed')
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 99999 }

        run_test! do |response|
          expect(response.status).to eq(404)
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not Authorized')
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # POST /student_tasks/start_task
  # ---------------------------------------------------------------------------
  path '/student_tasks/start_task' do
    post 'Start a task by response map ID' do
      tags 'StudentTasks'
      consumes 'application/json'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          response_map_id: { type: :integer }
        },
        required: ['response_map_id']
      }

      response '200', 'starts valid first task when no prerequisites' do
        before { allow_any_instance_of(Assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }
        let(:body) { { response_map_id: review_map.id } }

        run_test! do |response|
          expect([200, 403]).to include(response.status)
        end
      end

      response '403', 'blocks review task when prior quiz task is incomplete' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "Flow Start Quiz",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end
        before { allow_any_instance_of(Assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire) }
        let(:body) { { response_map_id: review_map.id } }

        run_test! do |response|
          expect(response.status).to eq(403)
        end
      end

      response '200', 'allows review task when prior quiz task is submitted' do
        let!(:questionnaire) do
          QuizQuestionnaire.create!(
            name: "Flow Start Quiz Done",
            instructor_id: instructor.id,
            min_question_score: 0,
            max_question_score: 5
          )
        end
        let!(:quiz_map) do
          map = QuizResponseMap.new(
            reviewer_id: participant.id,
            reviewee_id: participant.id,
            reviewed_object_id: assignment.id
          )
          map.save!(validate: false)
          map
        end
        before do
          allow_any_instance_of(Assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(questionnaire)
          Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)
        end
        let(:body) { { response_map_id: review_map.id } }

        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end

      response '404', 'response map not found' do
        let(:body) { { response_map_id: 99999 } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(response.status).to eq(404)
          expect(data['error']).to include('not found')
        end
      end

      response '403', 'rejects map owned by another user' do
        let!(:other_student) do
          User.create!(
            name: "other_flow",
            password_digest: "password",
            role_id: @roles[:student].id,
            full_name: "Other Flow",
            email: "other_flow@example.com"
          )
        end
        let(:token) { JsonWebToken.encode({ id: other_student.id }) }
        let(:Authorization) { "Bearer #{token}" }
        let(:body) { { response_map_id: review_map.id } }

        run_test! do |response|
          expect([403, 404]).to include(response.status)
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:body) { { response_map_id: review_map.id } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to eq('Not Authorized')
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Payload contract regression
  # ---------------------------------------------------------------------------
  path '/student_tasks/queue' do
    get 'Payload contract: queue response includes all required task keys' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'assignment_id', in: :query, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'task payload contains all required contract keys' do
        before { allow_any_instance_of(Assignment).to receive(:quiz_questionnaire_for_review_flow).and_return(nil) }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          if data.is_a?(Array) && data.any?
            task = data.first
            %w[task_type assignment_id response_map_id response_map_type reviewee_id team_participant_id].each do |key|
              expect(task).to have_key(key), "Expected task payload to include key '#{key}'"
            end
          end
        end
      end
    end
  end
end