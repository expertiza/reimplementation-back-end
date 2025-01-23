require 'rails_helper'

RSpec.describe Api::V1::TeamsParticipantsController, type: :controller do
  let(:student_role) { create(:role, :student) }
  let(:instructor_role) { create(:role, :instructor) }
  let(:instructor) { create(:user, role: create(:role, :instructor)) }
  let(:course) { create(:course, instructor_id: instructor.id) }
  let(:user) { create(:user, role: student_role) }
  let(:ta) { create(:teaching_assistant) }
  let(:team) { create(:team, parent_id: create(:assignment).id) }
  let(:participant) { create(:user, name: 'Test Participant') }
  let(:team_participant) { create(:teams_user, user: participant, team: team) }

  describe '#action_allowed?' do
    context 'when action is update_duties' do
      it 'allows access for students' do
        allow(controller).to receive(:current_user_has_student_privileges?).and_return(true)
        allow(controller).to receive(:params).and_return({ action: 'update_duties' })
        expect(controller.action_allowed?).to be true
      end

      it 'denies access for non-students' do
        allow(controller).to receive(:current_user_has_student_privileges?).and_return(false)
        allow(controller).to receive(:params).and_return({ action: 'update_duties' })
        expect(controller.action_allowed?).to be false
      end
    end

    context 'when action is not update_duties' do
      it 'allows access for TAs' do
        allow(controller).to receive(:current_user_has_ta_privileges?).and_return(true)
        allow(controller).to receive(:params).and_return({ action: 'list_participants' })
        expect(controller.action_allowed?).to be true
      end
    end
  end

  describe '#update_duties' do
  it 'updates the duties for the participant' do
    # Mock the TeamsUser object
    allow(TeamsUser).to receive(:find).with('1').and_return(team_participant)
    allow(team_participant).to receive(:update_attribute).with(:team_id, '2').and_return('OK')

    # Prepare request and session parameters
    request_params = {
      teams_user_id: '1', # ID of the TeamsUser to update
      teams_user: { team_id: '2' }, # Attribute to update
      participant_id: '1' # Participant ID for redirection
    }
    user_session = { user: stub_current_user(student, student.role.name, student.role) }

    # Perform the request
    get :update_duties, params: request_params, session: user_session

    # Expectations
    expect(response).to redirect_to('/student_teams/view?student_id=1')
    expect(team_participant).to have_received(:update_attribute).with(:team_id, '2')
  end
end


  describe '#list_participants' do
    it 'assigns participants and renders the view' do
      assignment = create(:assignment, id: team.parent_id)
      create_list(:teams_user, 5, team: team)

      get :list_participants, params: { id: team.id, page: 1 }

      expect(assigns(:team_participants).size).to eq(5)
      expect(assigns(:team)).to eq(team)
      expect(assigns(:assignment)).to eq(assignment)
    end
  end

  describe '#add_new_participant' do
    it 'renders the form for adding a new participant' do
      get :add_new_participant, params: { id: team.id }

      expect(response).to render_template(:add_new_participant)
    end
  end

  describe '#create_participant' do
    context 'when participant is valid' do
      it 'adds the participant and redirects' do
        allow(controller).to receive(:find_participant_by_name).and_return(participant)
        allow(controller).to receive(:find_team_by_id).and_return(team)
        allow(controller).to receive(:validate_participant_and_team).and_return(true)

        post :create_participant, params: { user: { name: participant.name }, id: team.id }

        expect(response).to redirect_to(controller: 'teams', action: 'list', id: team.parent_id)
      end
    end

    context 'when participant is invalid' do
      it 'flashes an error and redirects back' do
        allow(controller).to receive(:find_participant_by_name).and_return(nil)

        post :create_participant, params: { user: { name: 'Invalid User' }, id: team.id }

        expect(flash[:error]).to be_present
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe '#delete_participant' do
  it 'deletes the participant and redirects' do
    Rails.logger.debug "Creating test data..."
    assignment = create(:assignment)
    parent_team = create(:team, parent_id: assignment.id)
    team.update!(parent_id: parent_team.id)
    participant = create(:user)
    team_participant = create(:teams_user, team: team, user: participant)

    Rails.logger.debug "TeamsUser before deletion: #{TeamsUser.exists?(team_participant.id)}"

    delete :delete_participant, params: { id: team_participant.id }

    Rails.logger.debug "TeamsUser after deletion: #{TeamsUser.exists?(team_participant.id)}"

    expect(TeamsUser.exists?(team_participant.id)).to be_falsey # Verify deletion
    expect(response).to redirect_to(controller: 'teams', action: 'list', id: parent_team.id) # Verify redirection
  end
end


end
