require 'swagger_helper'

RSpec.describe 'Join Team Requests Controller', type: :request do

  path '/api/v1/join_team_requests/decline/{id}' do
    # You'll want to customize the parameter types...
    parameter name: 'id', in: :path, type: :string, description: 'id'

    post('decline join_team_request') do
      tags 'Join Team Requests'
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

  path '/api/v1/join_team_requests' do

    get('list join_team_requests') do
      tags 'Join Team Requests'
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
# Also test the failure cases, 422, 221
    post('create join_team_request') do
      parameter name: 'comments', in: :query, type: :string, description: 'comments'
      parameter name: 'team_id', in: :query, type: :integer, description: 'team_id'
      parameter name: 'assignment_id', in: :query, type: :integer, description: 'assignment_id'
      tags 'Join Team Requests'
      #do we need this one??
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

      response(201, 'created') do
        let(:join_team_request) do
          JoinTeamRequest.create(valid_join_team_request_params)
        end
        run_test! do
          expect(response.body).to include('"comments":"comment"')
        end
      end

      response(422, 'unprocessable entity') do
        let(:join_team_request) do
          #team
          JoinTeamRequest.create(invalid_join_team_request_params)
        end
        run_test!
      end
    end
  end

  path '/api/v1/join_team_requests/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'

    get('show join_team_request') do
      tags 'Join Team Requests'
      response(200, 'successful') do
        

        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: JSON.parse(response.body, symbolize_names: true)
            }
          }
        end
      # get request on /api/v1/questions/{id} returns 404 not found response when question id is not present in the database
      response(404, 'not_found') do
        let(:id) { 'invalid' }
          run_test! do
            expect(response.body).to include("Couldn't find JoinTeamRequest")
          end
      end
        run_test!
      end
    end

    patch('update join_team_request') do
      parameter name: 'join_team_request[comments]', in: :query, type: :string, description: 'comments'
      parameter name: 'join_team_request[status]', in: :query, type: :string, description: 'status'
      tags 'Join Team Requests'
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

    put('update join_team_request') do
      parameter name: 'join_team_request[comments]', in: :query, type: :string, description: 'comments'
      parameter name: 'join_team_request[status]', in: :query, type: :string, description: 'status'
      tags 'Join Team Requests'

      parameter name: :body_params, in: :body, schema: {
        type: :object,
        properties: {
          comments: { type: :string }
        }
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

      response(422, 'unprocessable entity') do
        let(:body_params) do
          {
            comments: -1
          }
        end
        schema type: :string
        run_test! do
          expect(response.body).to_not include('"comments":-1')
        end
    end

    delete('delete join_team_request') do
      tags 'Join Team Requests'

      response(204, 'successful') do
        run_test! do
          expect(JoinTeamRequest.exists?(id)).to eq(false)
        end
      end

      response(404, 'not found') do
        run_test! do
          expect(response.body).to include("Couldn't find JoinTeamRequest")
        end
      end
    end
  end
end
end
