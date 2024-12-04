describe 'GET #auto_complete_for_participant_name' do
  let(:team) { create(:team) }
  let(:participant) { create(:user, name: 'John Doe') }

  before do
    allow(Team).to receive(:find).and_return(team)
    allow(team).to receive(:get_possible_team_members).and_return([participant])
  end

  it 'fetches potential team members based on input' do
    session[:team_id] = team.id
    get :auto_complete_for_participant_name, params: { user: { name: 'John' } }
    expect(response).to be_successful
    expect(assigns(:potential_team_members)).to eq([participant])
  end

  it 'renders the auto-complete suggestions' do
    session[:team_id] = team.id
    get :auto_complete_for_participant_name, params: { user: { name: 'John' } }
    expect(response.body).to include(participant.name)
  end
end
describe 'POST #update_duties' do
  let(:team_participant) { create(:teams_participant) }

  it 'updates the duty of a team member' do
    post :update_duties, params: {
      teams_user_id: team_participant.id,
      teams_user: { duty_id: 2 },
      participant_id: team_participant.user_id
    }
    expect(team_participant.reload.duty_id).to eq(2)
    expect(response).to redirect_to(controller: 'student_teams', action: 'view', student_id: team_participant.user_id)
  end
end
describe 'GET #list_participants' do
  let(:team) { create(:team) }
  let(:assignment) { create(:assignment, id: team.parent_id) }
  let(:participant) { create(:teams_participant, team: team) }

  it 'lists participants of a team' do
    get :list_participants, params: { id: team.id }
    expect(assigns(:team)).to eq(team)
    expect(assigns(:assignment)).to eq(assignment)
    expect(assigns(:team_participants)).to include(participant)
  end
end
describe 'GET #add_new_participant' do
  let(:team) { create(:team) }

  it 'renders the form for adding a new participant' do
    get :add_new_participant, params: { id: team.id }
    expect(response).to render_template(:add_new_participant)
    expect(assigns(:team)).to eq(team)
  end
end
describe 'POST #create_participant' do
  let(:team) { create(:team) }
  let(:participant) { create(:user) }

  before do
    allow(Team).to receive(:find).and_return(team)
    allow(User).to receive(:find_by).and_return(participant)
    allow(team).to receive(:add_member_with_handling).and_return(true)
  end

  it 'adds a participant to a team successfully' do
    post :create_participant, params: { user: { name: participant.name }, id: team.id }
    expect(flash[:notice]).to include(participant.name)
    expect(response).to redirect_to(controller: 'teams', action: 'list', id: team.parent_id)
  end

  it 'shows an error when the participant is invalid' do
    allow(team).to receive(:add_member_with_handling).and_return(false)
    post :create_participant, params: { user: { name: participant.name }, id: team.id }
    expect(flash[:error]).to include('maximum number of members')
  end
end
describe 'DELETE #delete_participant' do
  let(:team) { create(:team) }
  let(:participant) { create(:user) }
  let(:team_participant) { create(:teams_participant, team: team, user: participant) }

  it 'deletes the participant from the team' do
    delete :delete_participant, params: { id: team_participant.id }
    expect(flash[:notice]).to include(participant.name)
    expect(response).to redirect_to(controller: 'teams', action: 'list', id: team.parent_id)
  end
end
