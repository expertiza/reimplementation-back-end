require 'swagger_helper'

RSpec.describe 'Account Requests API', type: :request do

  path '/api/v1/pending_request' do

    get('List Pending Account Requests') do
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

  path '/api/v1/processed_request' do

    get('List Processed Account Requests') do
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
          name: { type: :string },
          fullname: { type: :string },
          email: { type: :string },
          self_introduction: { type: :string },
          role_id: { type: :integer },
          institution_id: { type: :integer }
        },
        required: [ 'name', 'fullname', 'email', 'self_introduction', 'role_id', 'institution_id' ]
      }

      response(201, 'Created an Account Request with valid parameters') do
        let(:role) { Role.create(name: 'Student') }
        let(:institution) { Institution.create(name: 'North Carolina State University') }
        let(:account_request) { { name: 'useracc', fullname: 'User Account 1', email: 'useracc1@gmail.com', self_introduction: 'User 1 Intro', role_id: role.id, institution_id: institution.id } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Create an Account Request whose name already exists in Users table') do
        let(:role) { Role.create(name: 'Student') }
        let(:institution) { Institution.create(name: 'North Carolina State University') }
        let(:user) { User.create(name: 'useracc', fullname: 'User One', email: 'userone@gmail.com', role_id: role.id, password: 'password') }
        let(:account_request) { { name: user.name, fullname: 'User Account 1', email: 'useracc1@gmail.com', self_introduction: 'User 1 Intro', role_id: role.id, institution_id: institution.id } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'Create an Account Request whose email already exists in Users table') do
        let(:role) { Role.create(name: 'Student') }
        let(:institution) { Institution.create(name: 'North Carolina State University') }
        let(:user) { User.create(name: 'userone', fullname: 'User One', email: 'userone@gmail.com', role_id: role.id, password: 'password') }
        let(:account_request) { { name: 'useracc', fullname: 'User Account 1', email: user.email, self_introduction: 'User 1 Intro', role_id: role.id, institution_id: institution.id } }

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

    let(:role) { Role.create(name: 'Student') }
    let(:institution) { Institution.create(name: 'North Carolina State University') }
    let(:account_request) { AccountRequest.create(name: 'useracc', fullname: 'User Account 1', email: 'useracc1@gmail.com', self_introduction: 'User 1 Intro', role_id: role.id, institution_id: institution.id) }
    let(:id) { account_request.id }

    get('Show Account Request') do
      tags 'Account Requests'
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



    response(422, 'Create an Account Request with invalid parameters') do
        let(:account_request) { { name: 'useracc', fullname: 'User Account 1', email: 'useracc1', self_introduction: 'User 1 Intro', role_id: 0, institution_id: 1 } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

    patch('Update Account Request') do
      tags 'Account Requests'
      consumes 'application/json'
      parameter name: :account_request, in: :body, schema: {
        type: :object,
        properties: {
          status: { type: :string, example: 'Approved' }
        },
        required: ['status' ]
      }
      
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

      response(422, 'Approve account request but user with same name already exists') do
        
        let(:user) { User.create(name: 'user', fullname: 'User One', email: 'userone@gmail.com', role_id: role.id, password: 'password') }

        before do
          account_request.status = 'Approved'
          account_request.name = user.name
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

      response(422, 'Approve account request but user with same email already exists') do

        let(:user) { User.create(name: 'user', fullname: 'User One', email: 'userone@gmail.com', role_id: role.id, password: 'password') }

        before do
          account_request.status = 'Approved'
          account_request.name = user.email
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

      response(422, 'Invalid status in Patch') do

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
        required: ['status' ]
      }
      
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

      response(422, 'Approve account request but user with same name already exists') do
        
        let(:user) { User.create(name: 'user', fullname: 'User One', email: 'userone@gmail.com', role_id: role.id, password: 'password') }

        before do
          account_request.status = 'Approved'
          account_request.name = user.name
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

      response(422, 'Approve account request but user with same email already exists') do

        let(:user) { User.create(name: 'user', fullname: 'User One', email: 'userone@gmail.com', role_id: role.id, password: 'password') }

        before do
          account_request.status = 'Approved'
          account_request.name = user.email
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

      response(422, 'Invalid status in Patch') do

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
