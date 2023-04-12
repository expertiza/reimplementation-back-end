require 'swagger_helper'

RSpec.describe 'Account Requests API', type: :request do

  path '/api/v1/account_requests' do

    get('List Account Requests') do
      parameter name: 'history', in: :query, type: :boolean, description: 'Show previosuly approved or rejected account requests',
      required: true,
      schema: {
        type: :boolean,
        default: false,
        enum: [true, false]
      }

      tags 'Account Requests'
      produces 'application/json'

      response(200, 'successful') do

        let(:history) { false }
        let(:role) { Role.create(name: 'Administrator') }
        let(:user) { User.create(name: 'user', fullname: 'User One', email: 'userone@gmail.com', role_id: role.id, password: 'password') }
        before do
          ENV['TEST_USER_ID'] = user.id.to_s
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

      response(201, 'Created an Account Request') do
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
  end

  path '/api/v1/account_requests/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the Account Request'

    let(:role) { Role.create(name: 'Student') }
    let(:institution) { Institution.create(name: 'North Carolina State University') }
    let(:account_request) { AccountRequest.create(name: 'useracc', fullname: 'User Account 1', email: 'useracc1@gmail.com', self_introduction: 'User 1 Intro', role_id: role.id, institution_id: institution.id) }
    let(:id) { account_request.id }

    let(:admin_role) { Role.create(name: 'Administrator') }
    let(:user) { User.create(name: 'user', fullname: 'User One', email: 'userone@gmail.com', role_id: admin_role.id, password: 'password') }
    before do
      ENV['TEST_USER_ID'] = user.id.to_s
    end

    get('Show Account Request') do
      tags 'Account Requests'
      response(200, 'successful') do

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
          name: { type: :string },
          fullname: { type: :string },
          email: { type: :string },
          self_introduction: { type: :string },
          role_id: { type: :integer },
          institution_id: { type: :integer },
          status: { type: :string, example: 'Approved' }
        },
        required: [ 'name', 'fullname', 'email', 'self_introduction', 'role_id', 'institution_id', 'status' ]
      }
      
      response(200, 'successful') do

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
          name: { type: :string },
          fullname: { type: :string },
          email: { type: :string },
          self_introduction: { type: :string },
          role_id: { type: :integer },
          institution_id: { type: :integer },
          status: { type: :string, example: 'Approved' }
        },
        required: [ 'name', 'fullname', 'email', 'self_introduction', 'role_id', 'institution_id', 'status' ]
      }

      response(200, 'successful') do

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
      response(200, 'successful') do

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
end
