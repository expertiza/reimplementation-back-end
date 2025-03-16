require 'rails_helper'

RSpec.describe Api::V1::TeamsParticipantsController, type: :controller do
  let(:student_role) { create(:role, name: 'Student') }
  let(:ta_role) { create(:role, name: 'Teaching Assistant') }
  let(:student) { create(:user, role: student_role) }
  let(:ta) { create(:user, role: ta_role) }
  let(:instructor) { create(:user, role: create(:role, name: 'Instructor')) }
  let(:assignment) { create(:assignment) }
  let(:team) { create(:team, parent_id: assignment.id) }
  let(:participant) { create(:user, name: 'Test Participant') }
  let(:team_participant) { create(:teams_user, user: participant, team: team) }

  describe '#action_allowed?' do
    context 'when action is update_duties' do
      it 'allows access for students' do
        allow(controller).to receive(:has_privileges_of?).with('Student').and_return(true)
        allow(controller).to receive(:params).and_return({ action: 'update_duties' })
        expect(controller.action_allowed?).to be true
      end

      it 'denies access for non-students' do
        allow(controller).to receive(:has_privileges_of?).with('Student').and_return(false)
        allow(controller).to receive(:params).and_return({ action: 'update_duties' })
        expect(controller.action_allowed?).to be false
      end
    end

    context 'when action is not update_duties' do
      it 'allows access for TAs' do
        allow(controller).to receive(:has_privileges_of?).with('Teaching Assistant').and_return(true)
        allow(controller).to receive(:params).and_return({ action: 'list_participants' })
        expect(controller.action_allowed?).to be true
      end
    end
  end

  describe '#update_duties' do
    it 'updates the duties for the participant and redirects' do
      allow(TeamsUser).to receive(:find).with('1').and_return(team_participant)
      allow(team_participant).to receive(:update_attribute).with(:duty_id, '2').and_return(true)

      request_params = {
        teams_user_id: '1',
        teams_user: { duty_id: '2' },
        participant_id: '1'
      }

      post :update_duties, params: request_params

      expect(response).to redirect_to(controller: 'student_teams', action: 'view', student_id: '1')
      expect(team_participant).to have_received(:update_attribute).with(:duty_id, '2')
    end
  end

  describe '#list_participants' do
    it 'assigns participants and renders the view' do
      create_list(:teams_user, 5, team: team)
      get :list_participants, params: { id: team.id }
      expect(assigns(:team_participants).size).to eq(5)
      expect(assigns(:team)).to eq(team)
      expect(assigns(:assignment)).to eq(assignment)
    end
  end

  describe '#add_participant' do
    it 'adds a participant and redirects' do
      allow(controller).to receive(:find_participant_by_name).and_return(participant)
      allow(controller).to receive(:validate_participant_and_team).and_return(true)
      allow(team).to receive(:add_participants_with_validation).and_return(success: true)

      post :add_participant, params: { user: { name: participant.name }, id: team.id }
      expect(response).to redirect_to(controller: 'teams', action: 'list', id: team.parent_id)
    end

    it 'shows an error when participant is invalid' do
      allow(controller).to receive(:find_participant_by_name).and_return(nil)
      post :add_participant, params: { user: { name: 'Invalid User' }, id: team.id }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to(root_path)
    end
  end

  describe '#delete_participant' do
    it 'deletes the participant and redirects' do
      team_participant = create(:teams_user, team: team, user: participant)
      delete :delete_participant, params: { id: team_participant.id }
      expect(TeamsUser.exists?(team_participant.id)).to be_falsey
      expect(response).to redirect_to(controller: 'teams', action: 'list', id: team.parent_id)
    end
  end

  describe '#delete_selected_participants' do
    it 'deletes multiple participants and redirects' do
      team_participant1 = create(:teams_user, team: team, user: create(:user))
      team_participant2 = create(:teams_user, team: team, user: create(:user))
      params = { item: [team_participant1.id, team_participant2.id], id: team.id }
      delete :delete_selected_participants, params: params
      expect(TeamsUser.exists?(team_participant1.id)).to be_falsey
      expect(TeamsUser.exists?(team_participant2.id)).to be_falsey
      expect(response).to redirect_to(action: 'list_participants', id: team.id)
    end
  end
end
