require 'rails_helper'

RSpec.describe TeamsParticipantsController, type: :controller do
  let(:assignment) { create(:assignment) }
  let(:team) { create(:assignment_team, parent_id: assignment.id) }
  let(:participant) { create(:participant) }

  describe 'POST #create' do
    it 'adds a participant to the team' do
      post :create, params: { team_id: team.id, participant_id: participant.id }
      expect(response).to redirect_to(edit_assignment_team_path(team.id))
      expect(flash[:notice]).to match(/successfully added/)
    end

    it 'does not add duplicate participants' do
      TeamsParticipant.create(team_id: team.id, participant_id: participant.id)
      post :create, params: { team_id: team.id, participant_id: participant.id }
      expect(response).to redirect_to(edit_assignment_team_path(team.id))
      expect(flash[:error]).to match(/already a member/)
    end
  end

  describe 'DELETE #destroy' do
    let!(:teams_participant) { create(:teams_participant, team: team, participant: participant) }

    it 'removes a participant from the team' do
      delete :destroy, params: { id: teams_participant.id }
      expect(response).to redirect_to(edit_assignment_team_path(team.id))
      expect(flash[:notice]).to match(/successfully removed/)
    end
  end
end
