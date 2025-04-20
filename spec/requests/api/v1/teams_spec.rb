require 'rails_helper'

RSpec.describe Api::V1::TeamsController, type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:course) { create(:course) }
  let(:team) { create(:course_team, user: user, course: course) }
  let(:team_member) { create(:team_member, team: team, user: other_user) }

  before do
    allow_any_instance_of(Api::V1::TeamsController).to receive(:current_user).and_return(user)
  end

  describe 'GET /api/v1/teams' do
    it 'returns all teams' do
      team # Create the team
      get '/api/v1/teams'
      expect(response).to have_http_status(:success)
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(team.id)
    end
  end

  describe 'GET /api/v1/teams/:id' do
    it 'returns a specific team' do
      get "/api/v1/teams/#{team.id}"
      expect(response).to have_http_status(:success)
      expect(json_response['id']).to eq(team.id)
    end

    it 'returns 404 for non-existent team' do
      get '/api/v1/teams/0'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/teams' do
    it 'returns error for invalid params' do
      post '/api/v1/teams', params: { team: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to have_key('errors')
    end
  end

  describe 'Team Members' do
    describe 'GET /api/v1/teams/:id/members' do
      it 'returns all team members' do
        team_member # Create the team member
        get "/api/v1/teams/#{team.id}/members"
        expect(response).to have_http_status(:success)
        expect(json_response.size).to eq(1)
        expect(json_response.first['user_id']).to eq(other_user.id)
      end
    end

    describe 'POST /api/v1/teams/:id/members' do
      let(:new_user) { create(:user) }
      let(:valid_member_params) do
        {
          team_member: {
            user_id: new_user.id
          }
        }
      end

      it 'adds a new team member' do
        expect {
          post "/api/v1/teams/#{team.id}/members", params: valid_member_params
        }.to change(TeamMember, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response['user_id']).to eq(new_user.id)
      end

      it 'returns error when team is full' do
        team.update(max_team_size: 1)
        team_member # Create a team member to make the team full
        post "/api/v1/teams/#{team.id}/members", params: valid_member_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to have_key('errors')
      end
    end

    describe 'DELETE /api/v1/teams/:id/members/:user_id' do
      it 'removes a team member' do
        team_member # Create the team member
        expect {
          delete "/api/v1/teams/#{team.id}/members/#{other_user.id}"
        }.to change(TeamMember, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 for non-existent member' do
        delete "/api/v1/teams/#{team.id}/members/0"
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'Join Requests' do
    let(:team_join_request) { create(:team_join_request, team: team, user: other_user) }

    describe 'GET /api/v1/teams/:id/join_requests' do
      it 'returns all join requests' do
        team_join_request # Create the join request
        get "/api/v1/teams/#{team.id}/join_requests"
        expect(response).to have_http_status(:success)
        expect(json_response.size).to eq(1)
        expect(json_response.first['user_id']).to eq(other_user.id)
      end
    end

    describe 'POST /api/v1/teams/:id/join_requests' do
      let(:valid_join_request_params) do
        {
          team_join_request: {
            user_id: other_user.id,
            status: 'pending'
          }
        }
      end

      it 'creates a new join request' do
        expect {
          post "/api/v1/teams/#{team.id}/join_requests", params: valid_join_request_params
        }.to change(TeamJoinRequest, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response['user_id']).to eq(other_user.id)
      end

      it 'returns error for duplicate join request' do
        team_join_request # Create the join request
        post "/api/v1/teams/#{team.id}/join_requests", params: valid_join_request_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to have_key('errors')
      end
    end

    describe 'PUT /api/v1/teams/:id/join_requests/:id' do
      it 'updates join request status' do
        team_join_request # Create the join request
        put "/api/v1/teams/#{team.id}/join_requests/#{team_join_request.id}", params: { team_join_request: { status: 'accepted' } }
        expect(response).to have_http_status(:success)
        expect(json_response['status']).to eq('accepted')
      end

      it 'returns 404 for non-existent join request' do
        put "/api/v1/teams/#{team.id}/join_requests/0", params: { team_join_request: { status: 'accepted' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end 