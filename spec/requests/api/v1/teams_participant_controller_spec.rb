require 'rails_helper'

RSpec.describe TeamsParticipantsController, type: :controller do
  let(:assignment) { create(:assignment) }
  let(:team) { create(:assignment_team, assignment: assignment) }
  let(:user) { create(:user) }
  let(:participant) { create(:participant, user: user, assignment: assignment) }
  let(:teams_participant) { create(:teams_participant, team: team, participant: participant) }

  describe '#valid_participant?' do
    it 'returns true if participant exists' do
      allow(TeamsParticipant).to receive(:find_by).and_return(teams_participant)
      expect(controller.send(:valid_participant?, teams_participant.id)).to be true
    end

    it 'returns false if participant does not exist' do
      allow(TeamsParticipant).to receive(:find_by).and_return(nil)
      expect(controller.send(:valid_participant?, 999)).to be false
    end
  end

  describe '#update_duties' do
    it 'updates participant duties' do
      sign_in user
      put :update_duties, params: { id: teams_participant.id, duty: 'Review' }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe '#user_not_found_message' do
    it 'returns a user not found message' do
      expect(controller.send(:user_not_found_message)).to eq('User not found.')
    end
  end

  describe '#participant_not_found_message' do
    it 'returns a participant not found message' do
      expect(controller.send(:participant_not_found_message)).to eq('Participant not found.')
    end
  end

  describe '#create' do
    it 'creates a new TeamsParticipant' do
      expect {
        post :create, params: { team_id: team.id, user_id: user.id }
      }.to change(TeamsParticipant, :count).by(1)
    end
  end

  describe '#list' do
    it 'renders the list template' do
      get :list, params: { team_id: team.id }
      expect(response).to render_template(:list)
    end
  end

  describe '#action_allowed?' do
    it 'returns true for admin' do
      allow(controller).to receive(:current_user_role?).and_return(true)
      expect(controller.send(:action_allowed?)).to be true
    end

    it 'returns false for unauthorized users' do
      allow(controller).to receive(:current_user_role?).and_return(false)
      expect(controller.send(:action_allowed?)).to be false
    end
  end

  describe '#delete' do
    it 'deletes a TeamsParticipant' do
      teams_participant
      expect {
        delete :delete, params: { id: teams_participant.id }
      }.to change(TeamsParticipant, :count).by(-1)
    end
  end

  describe '#auto_complete_for_user_name' do
    it 'returns JSON results for auto-completion' do
      create(:user, name: 'John Doe')
      get :auto_complete_for_user_name, params: { name: 'John' }
      expect(response.content_type).to eq('application/json')
    end
  end

  describe '#new' do
    it 'renders the new template' do
      get :new, params: { team_id: team.id }
      expect(response).to render_template(:new)
    end
  end

  describe '#delete_selected' do
    it 'deletes multiple TeamsParticipants' do
      participant2 = create(:participant, assignment: assignment)
      teams_participant2 = create(:teams_participant, team: team, participant: participant2)

      expect {
        delete :delete_selected, params: { ids: [teams_participant.id, teams_participant2.id] }
      }.to change(TeamsParticipant, :count).by(-2)
    end
  end
end
