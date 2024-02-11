require 'swagger_helper'

RSpec.describe 'api/v1/teams_assignments', type: :request do

  # GET /teams_assignments/{id}/copy
  path '/api/v1/teams_assignments/{id}/copy' do
    parameter name: 'id', in: :path, type: :string, description: 'id'
    let(:teams_assignment) {
      teams_assignment.create(
        :users [create(:user)],
        :join_team_requests [],
        :team_node 0,
        :signed_up_teams 0,
        :bids 0,
      ) 
    }
    let(:id) { teams_assignment.id }
    get('copy teams_assignment') do
      tags 'teams_assignments'
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

  # GET /teams_assignments/
  path '/api/v1/teams_assignments' do
    get('list teams_assignments') do
      tags 'teams_assignments'
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

    # POST /teams_assignments/
    post('create teams_assignment') do
      tags 'teams_assignments'
      consumes 'application/json'
      parameter name: :teams_assignment, in: :body, schema: {
        type: :object,
        properties: {
          users: { type: user},
          join_team_requests: { type: TeamRequest},
          team_node: { type: int},
          signed_up_teams: { type: array},
          bids: { type: array},
        },
        required: ['teams_assignment']
      }
      response(201, 'successful') do
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

  # GET /teams_assignments/{id}
  path '/api/v1/teams_assignments/{id}' do
    parameter name: 'id', in: :path, type: :string, description: 'id'
    let(:teams_assignment) {
      teams_assignment.create(
        :users [create(:user)],
        :join_team_requests [],
        :team_node 0,
        :signed_up_teams 0,
        :bids 0,
      ) 
    }
    let(:id) { teams_assignment.id }
    get('show teams_assignment') do
      tags 'teams_assignments'
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

    # PATCH /teams_assignments/{id}
    patch('update teams_assignment') do
      tags 'teams_assignments'
      consumes 'application/json'
      parameter name: :teams_assignment, in: :body, schema: {
        type: :object,
        properties: {
          users: { type: user},
          join_team_requests: { type: TeamRequest},
          team_node: { type: int},
          signed_up_teams: { type: array},
          bids: { type: array},
        },
        required: ['teams_assignment']
      }
      let(:teams_assignment) {
        teams_assignment.create(
          :users [create(:user)],
          :join_team_requests [],
          :team_node 0,
          :signed_up_teams 0,
          :bids 0,
        ) 
      }
      let(:id) { teams_assignment.id }
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

    # PUT /teams_assignments/{id}
    put('update teams_assignment') do
      tags 'teams_assignments'
      consumes 'application/json'
      parameter name: :teams_assignment, in: :body, schema: {
        type: :object,
        properties: {
          users: { type: array},
          join_team_requests: { type: TeamRequest},
          team_node: { type: int},
          signed_up_teams: { type: array},
          bids: { type: array},
        },
        required: ['teams_assignment']
      }
      let(:teams_assignment) {
        teams_assignment.create(
          :users [create(:user)],
          :join_team_requests [],
          :team_node 0,
          :signed_up_teams 0,
          :bids 0,
        ) 
      }
      let(:id) { teams_assignment.id }
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

    # DELETE /teams_assignments/{id}
    delete('delete teams_assignment') do
      tags 'teams_assignments'
      let(:teams_assignment) {
        teams_assignment.create(
          :users [create(:user)],
          :join_team_requests [],
          :team_node 0,
          :signed_up_teams 0,
          :bids 0,
        ) 
      }
      let(:id) { teams_assignment.id }
      response(204, 'successful') do
        after do |example|
          example.metadata[:response][:content] = {
            'application/json' => {
              example: response.body
            }
          }
        end
        run_test!
      end
    end
  end
end
