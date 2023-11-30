require 'rails_helper'

RSpec.describe 'Teams API', type: :request do

  describe 'GET /teams' do
    context 'when teams exist' do
      let!(:teams) { create_list(:team, 3) }

      it 'returns a list of all teams' do
        get '/teams', as: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response.length).to eq(teams.length)

        team_names = teams.map(&:name)
        returned_team_names = parsed_response.map { |team| team['name'] }

        expect(returned_team_names).to match_array(team_names)
      end
    end

    context 'when no teams exist' do
      it 'returns an empty list' do
        get '/teams', as: :json

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to be_empty
      end
    end
  end
  describe 'POST /api/v1/teams' do
    context 'with valid parameters' do
      it 'creates a new team' do
        team_params = {name: 'New Team'}

        post '/api/v1/teams', params: { team: team_params }, as: :json

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')

        team = Team.last
        expect(JSON.parse(response.body)['id']).to eq(team.id)
      end
    end
  end
  describe 'PATCH/PUT /api/v1/teams/:id' do
    let(:team) { create(:team, name: 'Old Team Name') }

    context 'with valid parameters' do
      let(:new_team_name) { 'Updated Team Name' }

      it 'updates the team name' do
        put "/api/v1/teams/#{team.id}", params: { team: { name: new_team_name } }, as: :json

        team.reload
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')

        expect(JSON.parse(response.body)['id']).to eq(team.id)
        expect(team.name).to eq(new_team_name)
      end
    end
  end
  describe 'DELETE /api/v1/teams/:id' do
    let!(:team) { create(:team) }

    it 'deletes a team' do
      expect {
        delete "/api/v1/teams/#{team.id}"
      }.to change(Team, :count).by(-1)

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it 'returns a message indicating team deletion' do
      delete "/api/v1/teams/#{team.id}"

      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty

      # Optionally, you can check the response message
      expect(response.body).to eq({ message: "" }.to_json)
    end
  end
end
