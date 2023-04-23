require 'swagger_helper'

describe 'SignedUpTeams API' do
  path '/api/v1/signed_up_teams/sign_up' do
    # parameter name: :topic_id, in: :path, type: :integer, required: true
    # parameter name: :team_id, in: :path, type: :integer, required: true

    let(:topic_id) { create(:topic).id }
    let(:team) { create(:team) }
    let(:user) { create(:user) }

    post 'Creates a signed up team' do
      tags 'SignedUpTeams'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :team_id, in: :body, schema: {
        type: :object,
        properties: {
          team_id: { type: :integer },
          topic_id: { type: :integer },
        },
        required: %w[team_id topic_id]
      }

      let(:team_id) { team.id }

      response '201', 'signed up team created' do
        let(:team_id) { team.id }
        run_test!
      end

      response '422', 'invalid request' do
        let(:team_id) { nil }
        run_test!
      end
    end


  end

  path '/api/v1/signed_up_teams' do
    parameter name: :topic_id, in: :path, type: :integer, required: true

    let(:team) { create(:team) }
    let(:signed_up_team) { create(:signed_up_team, team: team) }

    get 'Retrieves signed up teams' do
      tags 'SignedUpTeams'
      produces 'application/json'

      response '200', 'signed up teams found' do
        schema type: :array,
               properties: {
                 id: { type: :integer },
                 topic_id: { type: :integer },
                 team_id: { type: :integer },
                 is_waitlisted: { type: :boolean },
                 preference_priority_number: { type: :integer }
               },
               required: [ 'id', 'topic_id', 'team_id', 'is_waitlisted', 'preference_priority_number']

        run_test!
      end

      response '404', 'signed up teams not found' do
        let(:topic_id) { 'invalid' }
        run_test!
      end
    end
    end

  path '/api/v1/signed_up_teams/{id}' do
    parameter name: :id, in: :path, type: :integer, required: true

    put 'Updates a signed up team' do
      tags 'SignedUpTeams'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :signed_up_team, in: :body, schema: {
        type: :object,
        properties: {
          is_waitlisted: { type: :boolean },
          preference_priority_number: { type: :integer }
        }
      }

      response '200', 'signed up team updated' do
        let(:signed_up_team) { signed_up_team }
        let(:signed_up_team) { { is_waitlisted: true } }
        run_test!
      end

      response '422', 'invalid request' do
        let(:signed_up_team) { { is_waitlisted: 'invalid' } }
        run_test!
      end
    end

    delete 'Deletes a signed up team' do
      tags 'SignedUpTeams'
      produces 'application/json'

      response '204', 'signed up team deleted' do
        let(:id) { signed_up_team.id }
        run_test!
      end

      response '422', 'invalid request' do
        let(:id) { 'invalid' }
        run_test!
      end
    end
  end
  end
