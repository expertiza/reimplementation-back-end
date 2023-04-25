require 'rails_helper'

RSpec.describe 'Api::V1::Duties', type: :request do
  let(:user) { create(:user) }

  describe 'GET #index' do
    it 'returns http success' do
      get '/api/v1/duties'
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /show' do
    it 'returns http success' do
      duty = Duty.create(name: 'Test Duty', max_members_for_duty: 1, assignment_id: 1)
      get "/api/v1/duty/#{duty.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /create' do
    it 'returns http success' do
      post '/api/v1/duties', params: { duty: { name: 'Test Duty', max_members_for_duty: 1} }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'PATCH /update' do
    it 'returns http success' do
      duty = Duty.create(name: 'Test Duty', max_members_for_duty: 1, assignment_id: 1)
      patch "/api/v1/duties/#{duty.id}", params:  { duty: { name: 'Test Duty', max_members_for_duty: 1 } }
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETE /destroy' do
    it 'returns http success' do
      duty = Duty.create(name: 'Test Duty', max_members_for_duty: 1, assignment_id: 1)
      delete "/api/v1/badges/#{duty.id}"
      expect(response).to have_http_status(:redirect)
    end
  end
end
