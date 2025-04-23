require 'rails_helper'

RSpec.describe 'TeamsParticipants', type: :request do
  let(:assignment) { create(:assignment) }
  let(:team) { create(:assignment_team, parent_id: assignment.id) }
  let(:participant) { create(:participant) }

  describe 'POST /teams_participants' do
    it 'adds a participant via API' do
      post "/teams_participants", params: { team_id: team.id, participant_id: participant.id }
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include('successfully added')
    end
  end

  describe 'DELETE /teams_participants/:id' do
    let!(:teams_participant) { create(:teams_participant, team: team, participant: participant) }

    it 'removes a participant via API' do
      delete "/teams_participants/#{teams_participant.id}"
      expect(response).to have_http_status(:redirect)
      follow_redirect!
      expect(response.body).to include('successfully removed')
    end
  end
end
