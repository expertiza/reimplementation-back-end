require 'swagger_helper'

RSpec.describe 'Users API', type: :request do

  path '/api/v1/users' do
    parameter name: 'role', in: :query, type: :string, description: 'Role of the User',
    required: true,
    schema: {
      type: 'string',
      default: 'Student',
      enum: ['Student', 'Instructor', 'Administrator', 'Super-Administrator', 'Unregistered user', 'Teaching Assistant']
    }

    post('create users and log in') do
      tags 'Create Users and Log In'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          fullname: { type: :string },
          email: { type: :string }
        },
        required: [ 'name', 'fullname', 'email' ]
      }

      response(201, 'Created a user') do
        let(:user) { { name: 'user', fullname: 'user one', email: 'user1@gmail.com' } }
        let(:role) { Role.create(name: 'Student').name }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end
  end
end
