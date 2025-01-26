require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'StudentTasks API', type: :request do

  before(:all) do
    # Create roles in hierarchy
    @super_admin = Role.find_or_create_by(name: 'Super Administrator')
    @admin = Role.find_or_create_by(name: 'Administrator', parent_id: @super_admin.id)
    @instructor = Role.find_or_create_by(name: 'Instructor', parent_id: @admin.id)
    @ta = Role.find_or_create_by(name: 'Teaching Assistant', parent_id: @instructor.id)
    @student = Role.find_or_create_by(name: 'Student', parent_id: @ta.id)
  end

  let(:studenta) {
    User.create(
      name: "studenta",
      password_digest: "password",
      role_id: @student.id,
      full_name: "Student A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      )
  }

  let(:token) { JsonWebToken.encode({id: studenta.id}) }
  let(:Authorization) { "Bearer #{token}" }

  path '/api/v1/student_tasks/list' do
    get 'student tasks list' do
      # Tag for testing purposes.
      tags 'StudentTasks'
      produces 'application/json'

      # Define parameter to send with request.
      parameter name: 'Authorization', :in => :header, :type => :string

      # Ensure an authorized request gets a 200 response.
      response '200', 'authorized request has success response' do
        run_test!
      end

      # Ensure an authorized test gets the right data for the logged-in user.
      response '200', 'authorized request has proper JSON schema' do
        # Run test and give expectations about result.
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to be_instance_of(Array)
          expect(data.length()).to be 5

          # Ensure the objects have the correct type.
          data.each do |task|
            expect(task['assignment']).to be_instance_of(String)
            expect(task['current_stage']).to be_instance_of(String)
            expect(task['stage_deadline']).to be_instance_of(String)
            expect(task['topic']).to be_instance_of(String)
            expect(task['permission_granted']).to be_in([true, false])

            # Not true in general case- this is only  for the seeded data.
            expect(task['assignment']).to eql(task['topic'])
          end
        end
      end

      # Ensure a request with an invalid bearer token gets a 401 response.
      response '401', 'unauthorized request has error response' do
        let(:'Authorization') {"Bearer "}
        run_test!
      end

      # Ensure a request with an invalid bearer token gets the proper error response.
      response '401', 'unauthorized request has error response' do
        let(:'Authorization') {"Bearer "}
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eql("Not Authorized")
        end
      end
    end
  end

  path '/api/v1/student_tasks/view' do
    get 'Retrieve a specific student task by ID' do
      tags 'StudentTasks'
      produces 'application/json'
      parameter name: 'id', in: :query, type: :Integer, required: true
      parameter name: 'Authorization', in: :header, type: :string

      response '200', 'successful retrieval of a student task' do
        let(:id) { 1 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['assignment']).to be_instance_of(String)
          expect(data['current_stage']).to be_instance_of(String)
          expect(data['stage_deadline']).to be_instance_of(String)
          expect(data['topic']).to be_instance_of(String)
          expect(data['permission_granted']).to be_in([true, false])
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