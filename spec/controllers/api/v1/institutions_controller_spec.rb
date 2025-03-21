require 'rails_helper'

RSpec.describe Api::V1::InstitutionsController, type: :controller do
  let!(:institution) { create(:institution) }  

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

  
  describe 'action_allowed?' do
    context 'when user has Instructor role' do
      it 'returns true' do
        user = create(:user, :instructor)  
        sign_in user  
        expect(controller.send(:action_allowed?)).to eq(true)
      end
    end

    context 'when user does not have Instructor role' do
      it 'returns false' do
        user = create(:user, :student)  
        sign_in user
        expect(controller.send(:action_allowed?)).to eq(false)
      end
    end
  end

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(json_response).to eq([institution.as_json])
    end
  end

  describe 'GET #show' do
    context 'when institution exists' do
      it 'returns a successful response' do
        get :show, params: { id: institution.id }
        expect(response).to have_http_status(:ok)
        expect(json_response).to eq(institution.as_json)
      end
    end

    context 'when institution does not exist' do
      it 'returns a not found error' do
        get :show, params: { id: 99999 }  
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to include('Institution not found')
      end
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_attributes) { { institution: { name: 'Test Institution' } } }

      it 'creates a new institution and returns a created response' do
        post :create, params: valid_attributes
        expect(response).to have_http_status(:created)
        expect(json_response['name']).to eq('Test Institution')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { institution: { name: '' } } }

      it 'does not create an institution and returns an unprocessable entity response' do
        post :create, params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('name')
      end
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:valid_attributes) { { institution: { name: 'Updated Institution' } } }

      it 'updates the institution and returns a successful response' do
        patch :update, params: { id: institution.id, institution: valid_attributes[:institution] }
        institution.reload
        expect(response).to have_http_status(:ok)
        expect(institution.name).to eq('Updated Institution')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { institution: { name: '' } } }

      it 'does not update the institution and returns an unprocessable entity response' do
        patch :update, params: { id: institution.id, institution: invalid_attributes[:institution] }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('name')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the institution and returns a successful response' do
      delete :destroy, params: { id: institution.id }
      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq(I18n.t('institution.deleted'))
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end