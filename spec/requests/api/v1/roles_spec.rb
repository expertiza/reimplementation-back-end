require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Roles API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:adm) {
    User.create(
      name: "adma",
      password_digest: "password",
      role_id: @roles[:admin].id,
      full_name: "Admin A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      )
  }

  let(:token) { JsonWebToken.encode({id: adm.id}) }
  let(:Authorization) { "Bearer #{token}" }

  path '/api/v1/roles' do
    get('list roles') do
      tags 'Roles'
      produces 'application/json'

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

    post('create role') do
      tags 'Roles'
      consumes 'application/json'
      parameter name: :role, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          parent_id: { type: :integer },
          default_page_id: { type: :integer }
        },
        required: [ 'name' ]
      }

      response(201, 'Created a role') do
        let(:role) { { name: 'Role 1' } }

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      response(422, 'invalid request') do
        let(:role) { { name: '' } }

        after do |example|
          puts "Response status: #{response.status}" if response
          puts "Response body: #{response.body}" if response&.body

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

  path '/api/v1/roles/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the role'

    let(:role) { Role.create(name: 'Test Role') }
    let(:id) { role.id }

    get('show role') do
      tags 'Roles'
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

    patch('update role') do
      tags 'Roles'
      consumes 'application/json'
      parameter name: :role, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          parent_id: { type: :integer },
          default_page_id: { type: :integer }
        },
        required: [ 'name' ]
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

      response(422, 'invalid request') do
        let(:role) { { name: '' } }
        let(:id) { Role.create(name: 'Test Role').id }

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

    put('update role') do
      tags 'Roles'
      consumes 'application/json'
      parameter name: :role, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          parent_id: { type: :integer },
          default_page_id: { type: :integer }
        },
        required: [ 'name' ]
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

      response(422, 'invalid request') do
        let(:role) { { name: '' } }
        let(:id) { Role.create(name: 'Test Role').id }

        after do |example|
          puts "Response status: #{response.status}" if response
          puts "Response body: #{response.body}" if response&.body
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end
    end

    delete('delete role') do
      tags 'Roles'
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
