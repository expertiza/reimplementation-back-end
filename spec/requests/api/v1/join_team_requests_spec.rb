require 'swagger_helper'

RSpec.describe 'Join Team Requests Controller', type: :request do

  # API endpoint to decline a join team request
  path '/api/v1/join_team_requests/decline/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'

    post('decline join_team_request') do
      tags 'Join Team Requests'
      response(200, 'successful') do
        # Include response example in Swagger documentation
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

  # API endpoint to list join team requests
  path '/api/v1/join_team_requests' do

    get('list join_team_requests') do
      tags 'Join Team Requests'
      response(200, 'successful') do
        # Include response example in Swagger documentation
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

    # API endpoint to create a join team request
    post('create join_team_request') do
      parameter name: 'comments', in: :query, type: :string, description: 'comments'
      parameter name: 'team_id', in: :query, type: :integer, description: 'team_id'
      parameter name: 'assignment_id', in: :query, type: :integer, description: 'assignment_id'
      tags 'Join Team Requests'

      # Success response
      response(200, 'success') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Created response with example data
      response(201, 'created') do
        let(:join_team_request) { JoinTeamRequest.create(valid_join_team_request_params) }
        run_test! do
          expect(response.body).to include('"comments":"comment"')
        end
      end

      # Unprocessable Entity response with example data
      response(422, 'unprocessable entity') do
        let(:join_team_request) { JoinTeamRequest.create(invalid_join_team_request_params) }
        run_test!
      end
    end
  end

  # API endpoint to show a specific join team request
  path '/api/v1/join_team_requests/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'

    get('show join_team_request') do
      tags 'Join Team Requests'
      response(200, 'successful') do
        # Include response example in Swagger documentation
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        # 404 response when the requested join team request is not found
        response(404, 'not_found') do
          let(:id) { 'invalid' }
          run_test! do
            expect(response.body).to include("Couldn't find JoinTeamRequest")
          end
        end
        run_test!
      end
    end

    # API endpoint to update a join team request using PATCH
    patch('update join_team_request') do
      parameter name: 'join_team_request[comments]', in: :query, type: :string, description: 'comments'
      parameter name: 'join_team_request[status]', in: :query, type: :string, description: 'status'
      tags 'Join Team Requests'
      response(200, 'successful') do
        # Include response example in Swagger documentation
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

    # API endpoint to update a join team request using PUT
    put('update join_team_request') do
      parameter name: 'join_team_request[comments]', in: :query, type: :string, description: 'comments'
      parameter name: 'join_team_request[status]', in: :query, type: :string, description: 'status'
      tags 'Join Team Requests'

      # Include request body parameter schema in Swagger documentation
      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          comments: { type: :string }
        }
      }
      response(200, 'successful') do
        # Include response example in Swagger documentation
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
        run_test!
      end

      # Unprocessable Entity response with example data
      response(422, 'unprocessable entity') do
        let(:body_params) { { comments: -1 } }
        schema type: :string
        run_test! do
          expect(response.body).to_not include('"comments":-1')
        end
      end
    end

    # API endpoint to delete a join team request
    delete('delete join_team_request') do
      tags 'Join Team Requests'

      # Successful response with example
      response(204, 'successful') do
        run_test! do
          expect(JoinTeamRequest.exists?(id)).to eq(false)
        end
      end

      # Not Found response with example
      response(404, 'not found') do
        run_test! do
          expect(response.body).to include("Couldn't find JoinTeamRequest")
        end
      end
    end
  end
end
