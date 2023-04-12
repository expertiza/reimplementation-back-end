require 'swagger_helper'

RSpec.describe 'Account Requests API', type: :request do

  path '/api/v1/account_requests' do

    get('List Account Requests') do
      tags 'Account Requests'
      produces 'application/json'

      response(200, 'successful') do

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

  #   post('create account_request') do
  #     tags 'account_requests'
  #     consumes 'application/json'
  #     parameter name: :account_request, in: :body, schema: {
  #       type: :object,
  #       properties: {
  #         name: { type: :string },
  #         parent_id: { type: :integer },
  #         default_page_id: { type: :integer }
  #       },
  #       required: [ 'name' ]
  #     }

  #     response(201, 'Created a account_request') do
  #       let(:account_request) { { name: 'account_request 1' } }

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end

  #     response(422, 'invalid request') do
  #       let(:account_request) { { name: '' } }

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  # end

  # path '/api/v1/account_requests/{id}' do
  #   parameter name: 'id', in: :path, type: :integer, description: 'id of the account_request'

  #   let(:account_request) { account_request.create(name: 'Test account_request') }
  #   let(:id) { account_request.id }

  #   get('show account_request') do
  #     tags 'account_requests'
  #     response(200, 'successful') do

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end

  #   patch('update account_request') do
  #     tags 'account_requests'
  #     consumes 'application/json'
  #     parameter name: :account_request, in: :body, schema: {
  #       type: :object,
  #       properties: {
  #         name: { type: :string },
  #         parent_id: { type: :integer },
  #         default_page_id: { type: :integer }
  #       },
  #       required: [ 'name' ]
  #     }
      
  #     response(200, 'successful') do

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end

  #     response(422, 'invalid request') do
  #       let(:account_request) { { name: '' } }
  #       let(:id) { account_request.create(name: 'Test account_request').id }

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end

  #   put('update account_request') do 
  #     tags 'account_requests'
  #     consumes 'application/json'
  #     parameter name: :account_request, in: :body, schema: {
  #       type: :object,
  #       properties: {
  #         name: { type: :string },
  #         parent_id: { type: :integer },
  #         default_page_id: { type: :integer }
  #       },
  #       required: [ 'name' ]
  #     }

  #     response(200, 'successful') do

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end

  #     response(422, 'invalid request') do
  #       let(:account_request) { { name: '' } }
  #       let(:id) { account_request.create(name: 'Test account_request').id }

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: JSON.parse(response.body, symbolize_names: true)
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end

  #   delete('delete account_request') do
  #     tags 'account_requests'
  #     response(204, 'successful') do

  #       after do |example|
  #         example.metadata[:response][:content] = {
  #           'application/json' => {
  #             example: ''
  #           }
  #         }
  #       end
  #       run_test!
  #     end
  #   end
  end
end
