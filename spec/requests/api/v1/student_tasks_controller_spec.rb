require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'StudentTasks API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name: "Instructor",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end

  let(:studenta) do
    User.create!(
      name: "studenta",
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student A",
      email: "testuser@example.com"
    )
  end

  let(:token) { JsonWebToken.encode({id: studenta.id}) }
  let(:Authorization) { "Bearer #{token}" }

  # -------------------------------------------------------------------------
  # /api/v1/student_tasks/list
  # -------------------------------------------------------------------------
  path '/api/v1/student_tasks/list' do
    get 'student tasks list' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'Authorization', in: :header, type: :string

      # Just a basic "200" test
      response '200', 'authorized request has success response' do
        run_test!
      end

      # The "proper JSON schema" test
      response '200', 'authorized request has proper JSON schema' do
        before do
          # 1) Create an Assignment
          assignment = Assignment.create!(
            name: "Sample Assignment",
            instructor: instructor
          )

          # 2) Create N Participants for our student, each with different data
          5.times do |i|
            Participant.create!(
              user_id: studenta.id,
              assignment_id: assignment.id,
              permission_granted: [true, false].sample,
              # store “stage” and “deadline” fields as your Participant model expects
              # e.g. might be:
              topic: "Topic #{i}",
              stage_deadline: (Time.now + (i + 1).days).to_s,
              # and if it has “current_stage” or something:
              current_stage: "Stage #{i}"
            )
          end
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_an(Array)
          expect(data.size).to eq(5)

          data.each do |task|
            # Because StudentTask is just a plain Ruby object,
            # we expect the controller to have built it from the Participant
            expect(task['assignment']).to        be_a(String)
            expect(task['current_stage']).to     be_a(String)
            expect(task['stage_deadline']).to    be_a(String)
            expect(task['topic']).to             be_a(String)
            expect(task['permission_granted']).to be_in([true, false])
          end
        end
      end

      # Unauthorized test
      response '401', 'unauthorized request has error response' do
        let(:'Authorization') { "Bearer " }
        run_test!
      end
    end
  end

  # -------------------------------------------------------------------------
  # /api/v1/student_tasks/view
  # -------------------------------------------------------------------------
  path '/api/v1/student_tasks/view' do
    get 'Retrieve a specific student task by ID' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'id', in: :query, type: :Integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      # 200 test
      response '200', 'successful retrieval of a student task' do
        let!(:assignment) do
          Assignment.create!(name: "Test Assignment", instructor: instructor)
        end

        # Create *one* participant for the student
        let!(:participant) do
          Participant.create!(
            user_id: studenta.id,
            assignment_id: assignment.id,
            current_stage: "Review",
            stage_deadline: (Time.now + 7.days).to_s,
            topic: "Topic XYZ",
            permission_granted: true
          )
        end

        # This “id” is the participant’s ID to be looked up
        let(:id) { participant.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assignment']).to        eq("Test Assignment")
          expect(data['current_stage']).to     eq("Review")
          expect(data['stage_deadline']).to    be_a(String)  # e.g. "YYYY-MM-DD..."
          expect(data['topic']).to             eq("Topic XYZ")
          expect(data['permission_granted']).to be true
        end
      end

      response '500', 'participant not found' do
        let(:id) { -1 }
        run_test! do |response|
          expect(response.status).to eq(500)
        end
      end

      response '401', 'unauthorized request has error response' do
        let(:'Authorization') { "Bearer " }
        let(:id) { 'any_id' }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eql("Not Authorized")
        end
      end
    end
  end
end
