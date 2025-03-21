require 'rails_helper'

RSpec.describe Api::V1::RolesController, type: :controller do
  let!(:role) { create(:role) }
  let!(:admin_user) { create(:user, role: create(:role, name: 'Administrator')) }
  let!(:subordinate_role) { create(:role, parent: role) }

    # MYSQL wait check before tests
    before(:all) do 
      retries = 0
      begin
        ActiveRecord::Base.establish_connection 
        ActiveRecord::Base.connection.execute('SELECT 1')
      rescue => e
        retries += 1
        if retries < 10
          puts "Waiting for MySQL... Retry #{retries}/10"
          sleep 5
          retry 
        else 
          raise e
        end 
      end 
    end

  before do
    sign_in admin_user
  end

  describe 'GET #index' do
    it 'returns all roles' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(json_response.length).to eq(1)
    end
  end

  describe 'GET #show' do
    context 'when the role exists' do
      it 'returns the role' do
        get :show, params: { id: role.id }
        expect(response).to have_http_status(:ok)
        expect(json_response['name']).to eq(role.name)
      end
    end

    context 'when the role does not exist' do
      it 'returns an error' do
        get :show, params: { id: 99999 }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Parameter missing')
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) { { role: { name: 'New Role' } } }

      it 'creates a new role' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
        expect(json_response['name']).to eq('New Role')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { role: { name: '' } } }

      it 'returns an error' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['name']).to include("can't be blank")
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:valid_params) { { role: { name: 'Updated Role' } } }

      it 'updates the role' do
        patch :update, params: { id: role.id, role: valid_params }
        expect(response).to have_http_status(:ok)
        expect(json_response['name']).to eq('Updated Role')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { role: { name: '' } } }

      it 'returns an error' do
        patch :update, params: { id: role.id, role: invalid_params }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['name']).to include("can't be blank")
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when the role exists' do
      it 'deletes the role and returns a success message' do
        delete :destroy, params: { id: role.id }
        expect(response).to have_http_status(:no_content)
        expect(json_response['message']).to eq("Role #{role.name} with id #{role.id} deleted successfully!")
      end
    end

    context 'when the role does not exist' do
      it 'returns an error' do
        delete :destroy, params: { id: 99999 }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('Parameter missing')
      end
    end
  end

  describe 'GET #subordinate_roles' do
    it 'returns the subordinate roles of the current user' do
      get :subordinate_roles
      expect(response).to have_http_status(:ok)
      expect(json_response.length).to eq(1)
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end