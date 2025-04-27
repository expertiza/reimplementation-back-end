require 'swagger_helper'
require 'json_web_token'
RSpec.describe 'Institutions API', type: :request do
    before(:all) do
      @roles = create_roles_hierarchy
    end

    let(:prof) { User.create(
      name: "profa",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Prof A",
      email: "testuser@example.com",
      mru_directory_path: "/home/testuser",
      ) }

    let(:token) { JsonWebToken.encode({id: prof.id}) }
    let(:Authorization) { "Bearer #{token}" }
  path '/api/v1/institutions' do
    get('list institutions') do
      tags 'Institutions'
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

    post('create institution') do
      tags 'Institutions'
      consumes 'application/json'
      parameter name: :institution, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string }
        },
        required: [ 'name' ]
      }

      response(201, 'Created a institution') do
        let(:institution) { { name: 'institution 1' } }

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
        let(:institution) { { name: '' } }

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

  path '/api/v1/institutions/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'id of the institution'

    let(:institution) { Institution.create(name: 'Test institution') }
    let(:id) { institution.id }

    get('show institution') do
      tags 'Institutions'
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

    patch('update institution') do
      tags 'Institutions'
      consumes 'application/json'
      parameter name: :institution, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string }
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
        let(:institution) { { name: '' } }
        let(:id) { Institution.create(name: 'Test institution').id }

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

    put('update institution') do 
      tags 'Institutions'
      consumes 'application/json'
      parameter name: :institution, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string }
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
        let(:institution) { { name: '' } }
        let(:id) { Institution.create(name: 'Test institution').id }

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

    delete('delete institution') do
      tags 'Institutions'
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
