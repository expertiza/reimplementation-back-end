require 'swagger_helper'

def login_user()
  # Give the login details of a DB-seeded user. (see seeds.rb)
  login_details = {
    user_name: "john",
    password: "password123"
  }

  # Make the request to the login function.
  post '/login', params: login_details

  # return the token from the response
  json_response = JSON.parse(response.body)
  json_response['token']
end

describe 'StudentTasks API', type: :request do

  # Re-login and get the token after each request.
  before(:each) do
    @token = login_user
  end

  path '/api/v1/student_tasks/list' do
    get 'student tasks list' do
      # Tag for testing purposes.
      tags 'StudentTasks'
      produces 'application/json'

      # Define parameter to send with request.
      parameter name: 'Authorization', :in => :header, :type => :string

      # Ensure an authorized request gets a 200 response.
      response '200', 'authorized request has success response' do
        # Attach parameter to request.
        let(:'Authorization') {"Bearer #{@token}"}

        run_test!
      end

      # Ensure an authorized test gets the right data for the logged-in user.
      response '200', 'authorized request has proper JSON schema' do
        # Attach parameter to request.
        let(:'Authorization') {"Bearer #{@token}"}

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
end