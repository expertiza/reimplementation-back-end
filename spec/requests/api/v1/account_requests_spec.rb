require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Account Requests API', type: :request do
  before(:all) do
    # Create roles in hierarchy
    @super_admin = Role.find_or_create_by(name: 'Super Administrator')
    @admin = Role.find_or_create_by(name: 'Administrator', parent_id: @super_admin.id)
    @instructor = Role.find_or_create_by(name: 'Instructor', parent_id: @admin.id)
    @ta = Role.find_or_create_by(name: 'Teaching Assistant', parent_id: @instructor.id)
    @student = Role.find_or_create_by(name: 'Student', parent_id: @ta.id)
  end

  let(:prof) {
    User.create(
      name: "profa",
      password_digest: "password",
      role_id: @instructor.id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      )
  }

  let(:token) { JsonWebToken.encode({ id: prof.id }) }
  let(:Authorization) { "Bearer #{token}" }
  let(:institution) { Institution.create(name: "NC State") }

  path '/api/v1/account_requests/pending' do
    # List all Pending Account Requests
    get('List all Pending Account Requests') do
      tags 'Account Requests'
      produces 'application/json'

      response(200, 'List Pending Account Requests') do
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

  path '/api/v1/account_requests/processed' do
    # List all Processed Account Requests
    get('List all Processed Account Requests') do
      tags 'Account Requests'
      produces 'application/json'

      response(200, 'List Processed Account Requests') do
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

  path '/api/v1/account_requests' do
    post('Create Account Request') do
      tags 'Account Requests'
      consumes 'application/json'
      parameter name: :account_request, in: :body, schema: {
        type: :object,
        properties: {
          username: { type: :string },
          full_name: { type: :string },
          email: { type: :string },
          introduction: { type: :string },
          role_id: { type: :integer },
          institution_id: { type: :integer }
        },
        required: %w[username full_name email introduction role_id institution_id]
      }

      # Attempt to Create an Account Request with valid parameters
      response(201, 'Attempt to Create an Account Request with valid parameters') do
        let(:account_request) do
          { username: 'useracc', full_name: 'User Account 1', email: 'useracc1@gmail.com', introduction: 'User 1 Intro',
            role_id: @student.id, institution_id: institution.id }
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Attempt to Create an Account Request with missing parameters
      response(422, 'Attempt to Create an Account Request with missing parameters') do
        let(:account_request) { { introduction: 'User 1 Intro', role_id: @student.id, institution_id: institution.id } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Attempt to Create an Account Request with invalid parameters
      response(422, 'Attempt to Create an Account Request with invalid parameters') do
        let(:account_request) do
          { username: 'useracc', full_name: 'User Account 1', email: 'useracc1', introduction: 'User 1 Intro', role_id: 0,
            institution_id: 1 }
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Attempt to Create an Account Request whose username already exists in Users table
      response(422, 'Attempt to Create an Account Request whose username already exists in Users table') do
        let(:user) do
          User.create(name: 'useracc', full_name: 'User One', email: 'userone@gmail.com', role_id: @student.id,
                      password: 'password')
        end
        let(:account_request) do
          { username: user.name, full_name: 'User Account 1', email: 'useracc1@gmail.com', introduction: 'User 1 Intro',
            role_id: @student.id, institution_id: institution.id }
        end

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Create an Account Request whose email already exists in Users table
      response(201, 'Create an Account Request whose email already exists in Users table') do
        let(:user) do
          User.create(name: 'userone', full_name: 'User One', email: 'userone@gmail.com', role_id: @student.id,
                      password: 'password')
        end
        let(:account_request) do
          { username: 'useracc', full_name: 'User Account 1', email: user.email, introduction: 'User 1 Intro', role_id: @student.id,
            institution_id: institution.id }
        end

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

    path '/api/v1/account_requests/{id}' do
      parameter name: 'id', in: :path, type: :integer, description: 'id of the Account Request'
      
      let(:account_request) do
        AccountRequest.create(username: 'useracc', full_name: 'User Account 1', email: 'useracc1@gmail.com',
                              introduction: 'User 1 Intro', role_id: @student.id, institution_id: institution.id)
      end
      let(:id) { account_request.id }

      get('Show a specific Account Request by id') do
        tags 'Account Requests'

        # Retrieve a specific account request with valid id
        response(200, 'Retrieve a specific account request with valid id') do
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

      patch('Update Account Request') do
        tags 'Account Requests'
        consumes 'application/json'
        parameter name: :account_request, in: :body, schema: {
          type: :object,
          properties: {
            status: { type: :string, example: 'Approved' }
          },
          required: ['status']
        }

        # Approve account request
        response(200, 'Approve account request') do
          before do
            account_request.status = 'Approved'
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          run_test!
        end

        # Attempt to Approve account request but user with same name already exists
        response(422, 'Attempt to Approve account request but user with same name already exists') do
          let(:user) do
            User.create(name: 'user', full_name: 'User One', email: 'userone@gmail.com', role_id: @student.id,
                        password: 'password')
          end

          before do
            account_request.status = 'Approved'
            account_request.username = user.name
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          run_test!
        end

        # Reject account request
        response(200, 'Reject account request') do
          before do
            account_request.status = 'Rejected'
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          run_test!
        end

        # Attempt to send Invalid status in Patch
        response(422, 'Attempt to send Invalid status in Patch') do
          before do
            account_request.status = 'Random String'
          end

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

      put('Update Account Request') do
        tags 'Account Requests'
        consumes 'application/json'
        parameter name: :account_request, in: :body, schema: {
          type: :object,
          properties: {
            status: { type: :string, example: 'Approved' }
          },
          required: ['status']
        }

        # Approve account request
        response(200, 'Approve account request') do
          before do
            account_request.status = 'Approved'
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          run_test!
        end

        # Attempt to Approve account request but user with same username already exists
        response(422, 'Attempt to Approve account request but user with same username already exists') do
          let(:user) do
            User.create(name: 'user', full_name: 'User One', email: 'userone@gmail.com', role_id: @student.id,
                        password: 'password')
          end

          before do
            account_request.status = 'Approved'
            account_request.username = user.name
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          run_test!
        end

        # Reject account request if user with same email already exists
        response(422, 'Attempt to Approve account request but user with same email already exists') do
          let(:user) do
            User.create(name: 'user', full_name: 'User One', email: 'userone@gmail.com', role_id: @student.id,
                        password: 'password')
          end

          before do
            account_request.status = 'Approved'
            account_request.email = user.email
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          run_test!
        end

        # Reject an account request
        response(200, 'Reject account request') do
          before do
            account_request.status = 'Rejected'
          end

          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: JSON.parse(response.body, symbolize_names: true)
              }
            }
          end
          run_test!
        end

        # Attempt to send Invalid status in PUT
        response(422, 'Attempt to send Invalid status in PUT') do
          before do
            account_request.status = 'Random String'
          end

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

      # Delete an Account Request
      delete('Delete Account Request') do
        tags 'Account Requests'
        response(204, 'successful') do
          after do |example|
            example.metadata[:response][:content] = {
              'application/json' => {
                example: ''
              }
            }
          end
          run_test!
        end
      end
    end
  end
end
