require 'swagger_helper'

def login_user()
  # Give the login details of a DB-seeded user.
  login_details = {
    user_name: "john",
    password: "password123"
  }

  # Make the request to the login function.
  post '/login', params: login_details

  # Get the token from the response
  json_response = JSON.parse(response.body)
  json_response['token']
end

describe 'StudentTasks API', type: :request do

  before(:each) do
    @token = login_user
  end

  path '/api/v1/student_tasks/list' do
    get 'student tasks list' do
      tags 'StudentTasks'
      produces 'application/json'

      parameter name: 'Authorization', :in => :header, :type => :string

      response '200', 'authorized request' do
        let(:'Authorization') {"Bearer #{@token}"}
        run_test!
      end

      response '401', 'unauthorized request' do
        let(:'Authorization') {"Bearer "}
        run_test!
      end

    end


  end
end