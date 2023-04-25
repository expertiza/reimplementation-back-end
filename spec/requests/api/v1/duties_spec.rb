RSpec.describe Api::V1::DutiesController, type: :controller do
  let(:assignment) { create(:assignment) }
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe 'GET #index' do
    let!(:duties) { create_list(:duty, 3, assignment: assignment) }

    it 'returns a success response' do
      get :index, params: { assignment_id: assignment.id }
      expect(response).to be_successful
    end

    it 'assigns duties' do
      get :index, params: { assignment_id: assignment.id }
      expect(assigns(:duties)).to eq(duties)
    end
  end

  describe 'GET #show' do
    let(:duty) { create(:duty, assignment: assignment) }

    it 'returns a success response' do
      get :show, params: { assignment_id: assignment.id, id: duty.id }
      expect(response).to be_successful
    end

    it 'assigns duty' do
      get :show, params: { assignment_id: assignment.id, id: duty.id }
      expect(assigns(:duty)).to eq(duty)
    end
  end

  describe 'GET #new' do
    it 'returns a success response' do
      get :new, params: { assignment_id: assignment.id }
      expect(response).to be_successful
    end

    it 'assigns a new duty' do
      get :new, params: { assignment_id: assignment.id }
      expect(assigns(:duty)).to be_a_new(Duty)
    end
  end

  describe 'GET #edit' do
    let(:duty) { create(:duty, assignment: assignment) }

    it 'returns a success response' do
      get :edit, params: { assignment_id: assignment.id, id: duty.id }
      expect(response).to be_successful
    end

    it 'assigns duty' do
      get :edit, params: { assignment_id: assignment.id, id: duty.id }
      expect(assigns(:duty)).to eq(duty)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:duty_attributes) { attributes_for(:duty) }

      it 'creates a new duty' do
        expect {
          post :create, params: { assignment_id: assignment.id, duty: duty_attributes }
        }.to change(Duty, :count).by(1)
      end

      it 'redirects to edit_assignment_path' do
        post :create, params: { assignment_id: assignment.id, duty: duty_attributes }
        expect(response).to redirect_to(edit_assignment_path(assignment))
      end
    end

    context 'with invalid params' do
      let(:duty_attributes) { attributes_for(:duty, name: nil) }

      it 'does not create a new duty' do
        expect {
          post :create, params: { assignment_id: assignment.id, duty: duty_attributes }
        }.to_not change(Duty, :count)
      end

      it 'redirects to new duty page and shows error' do
        post :create, params: { assignment_id: assignment.id, duty: duty_attributes }
        expect(response).to redirect_to(action: :new, assignment_id: assignment.id)
        expect(flash[:error]).to be_present
      end
    end
  end
end
