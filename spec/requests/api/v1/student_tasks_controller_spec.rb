# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'StudentTasks API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "instructor_st",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor_st@example.com"
    )
  end

  let(:studenta) do
    User.create!(
      name: "studenta_st",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student A",
      email: "studenta_st@example.com"
    )
  end

  let(:token) { JsonWebToken.encode({ id: studenta.id }) }
  let(:Authorization) { "Bearer #{token}" }

  let!(:assignment) do
    Assignment.create!(
      name: "ST Sample Assignment",
      instructor: instructor
    )
  end

  let!(:participant) do
    AssignmentParticipant.create!(
      user_id: studenta.id,
      parent_id: assignment.id,
      handle: studenta.name,
      current_stage: "Review",
      stage_deadline: (Time.now + 7.days).to_s,
      topic: "Topic XYZ",
      permission_granted: true
    )
  end

  let!(:team) do
    AssignmentTeam.create!(
      name: "ST Team",
      parent_id: assignment.id
    )
  end

  let!(:teams_participant) do
    TeamsParticipant.create!(
      team: team,
      participant: participant,
      user: studenta
    )
  end

  let!(:review_map) do
    ReviewResponseMap.create!(
      reviewer_id: participant.id,
      reviewee_id: participant.id,
      reviewed_object_id: assignment.id
    )
  end

  # -------------------------------------------------------------------------
  # /student_tasks/list
  # -------------------------------------------------------------------------
  path '/student_tasks/list' do
    get 'List student tasks for current user' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'authorized request returns list of tasks' do
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Not Authorized")
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # /student_tasks/view
  # -------------------------------------------------------------------------
  path '/student_tasks/view' do
    get 'Retrieve a specific student task by participant ID' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'id', in: :query, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'successful retrieval of a student task' do
        let(:id) { participant.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assignment']).to eq("ST Sample Assignment")
          expect(data['current_stage']).to eq("Review")
          expect(data['topic']).to eq("Topic XYZ")
          expect(data['permission_granted']).to be true
        end
      end

      response '500', 'participant not found returns error' do
        let(:id) { -1 }
        run_test! do |response|
          expect(response.status).to eq(500)
        end
      end

      

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:id) { participant.id }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Not Authorized")
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # /student_tasks/queue
  # -------------------------------------------------------------------------
  path '/student_tasks/queue' do
    get 'Get task queue for an assignment' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'assignment_id', in: :query, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'returns queue of response maps' do
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to include('not found')
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Not Authorized")
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # /student_tasks/next_task
  # -------------------------------------------------------------------------
  path '/student_tasks/next_task' do
    get 'Get the next incomplete task for an assignment' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'assignment_id', in: :query, type: :integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'returns next task or all complete message' do
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          expect([200]).to include(response.status)
        end
      end

      response '404', 'assignment not found' do
        let(:assignment_id) { 99999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to include('not found')
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:assignment_id) { assignment.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Not Authorized")
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  # /student_tasks/start_task
  # -------------------------------------------------------------------------
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

      response '200', 'task started or blocked by queue ordering' do
        let(:body) { { response_map_id: review_map.id } }
        run_test! do |response|
          expect([200, 403]).to include(response.status)
        end 
      end

      response '404', 'response map not found' do
        let(:body) { { response_map_id: 99999 } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['error']).to include('not found')
        end
      end

      response '401', 'unauthorized request returns error' do
        let(:Authorization) { "Bearer " }
        let(:body) { { response_map_id: review_map.id } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Not Authorized")
        end
      end
    end
  end
end