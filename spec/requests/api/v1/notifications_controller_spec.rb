require 'rails_helper'

RSpec.describe Api::V1::NotificationsController, type: :controller do
  let(:admin) { create(:user, role: 'Admin') }
  let(:student) { create(:user, role: 'Student') }
  let(:notification) { create(:notification) }

  describe 'GET #index' do
    before { sign_in admin }

    it 'returns notifications for the current user' do
      get :index
      expect(response).to have_http_status(:ok)
      expect(json_response).to include(notification)
    end

    it 'denies access to unauthorized users' do
      sign_out admin
      sign_in student
      get :index
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #create' do
    context 'with valid attributes' do
      it 'creates a new notification' do
        expect {
          post :create, params: { notification: attributes_for(:notification) }
        }.to change(Notification, :count).by(1)
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors' do
        post :create, params: { notification: { subject: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
