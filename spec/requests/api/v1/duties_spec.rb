require 'swagger_helper'

RSpec.describe 'api/v1/duties', type: :request do

  path '/api/v1/duties' do

    get('list duties') do
      tags 'Duties'
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

    post('create duty') do
      tags 'Duties'
      description 'Create a new duty'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :duty, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          max_members_for_duty: { type: :integer },
          assignment_id: { type: :integer }
        },
        required: [ 'name', 'max_members_for_duty', 'assignment_id']
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
  end

  path '/api/v1/duties/{id}' do
    # You'll want to customize the parameter types...
    parameter name: 'id', in: :path, type: :string, description: 'id'

    get('show duty') do
      tags 'Duties'
      response(200, 'successful') do
        let(:id) { '123' }

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

    patch('update duty') do
      tags 'Duties'
      description 'Update a duty'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string
      parameter name: :duty, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          max_members_for_duty: { type: :integer },
          assignment_id: { type: :integer }
        }
      }

      response(200, 'successful') do
        let(:id) { '123' }
        let(:duty) { { name: 'Updated Duty Name', max_members_for_duty: 2, assignment_id: 456 } }

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

    delete('delete duty') do
      tags 'Duties'
      response(200, 'successful') do
        let(:id) { '123' }

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
