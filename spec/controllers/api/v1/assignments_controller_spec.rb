require 'rails_helper'

RSpec.describe 'Assignments API', type: :request do
  let!(:assignment) { Assignment.create(name: "Test Assignment", description: "Test Desc", due_date: "2025-12-31") }

  # Stub authentication if needed (based on your app setup)
  before do
    allow_any_instance_of(Api::V1::AssignmentsController).to receive(:authenticate_user!).and_return(true)
  end

  describe 'GET /api/v1/assignments' do
    it 'returns all assignments' do
      get '/api/v1/assignments'
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.first['name']).to eq('Test Assignment')
    end
  end

  describe 'GET /api/v1/assignments/:id' do
    it 'returns a specific assignment' do
      get "/api/v1/assignments/#{assignment.id}"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(assignment.id)
    end

    it 'returns 404 if assignment not found' do
      get "/api/v1/assignments/99999"
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Assignment not found')
    end
  end

  describe 'POST /api/v1/assignments' do
    it 'creates a new assignment with valid params' do
      expect {
        post '/api/v1/assignments', params: { assignment: { name: 'New Assignment', description: 'Desc', due_date: '2025-11-30' } }, as: :json
      }.to change(Assignment, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it 'returns errors with invalid params' do
      post '/api/v1/assignments', params: { assignment: { name: '', description: '', due_date: '' } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).not_to be_empty
    end
  end

  describe 'PUT /api/v1/assignments/:id' do
    it 'updates an assignment' do
      put "/api/v1/assignments/#{assignment.id}", params: { assignment: { name: 'Updated Name' } }, as: :json
      expect(response).to have_http_status(:ok)
      assignment.reload
      expect(assignment.name).to eq('Updated Name')
    end

    it 'returns errors with invalid update' do
      put "/api/v1/assignments/#{assignment.id}", params: { assignment: { name: '' } }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Update failed')
    end
  end

  describe 'DELETE /api/v1/assignments/:id' do
    it 'deletes an assignment' do
      expect {
        delete "/api/v1/assignments/#{assignment.id}"
      }.to change(Assignment, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 if assignment not found' do
      delete "/api/v1/assignments/99999"
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to eq('Assignment not found')
    end
  end
end
