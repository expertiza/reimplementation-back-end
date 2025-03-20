require 'rails_helper'

RSpec.describe Api::V1::AssignmentsController, type: :controller do
  let!(:instructor) { User.create!(name: "Instructor", email: "instructor@example.com", password: "password123") }
  let!(:valid_attributes) do
    {
      name: "Test Assignment",
      description: "Test Desc",
      due_date: "2025-12-31",
      instructor_id: instructor.id
    }
  end
   let!(:assignment) { Assignment.create!(valid_attributes) }
    
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
  end

  describe 'POST /api/v1/assignments' do
    it 'creates a new assignment with valid params' do
      expect {
        post '/api/v1/assignments', params: { assignment: { name: 'New Assignment', description: 'Desc', due_date: '2025-11-30', instructor_id: instructor.id } }, as: :json
      }.to change(Assignment, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe 'PUT /api/v1/assignments/:id' do
    it 'updates an assignment' do
      put "/api/v1/assignments/#{assignment.id}", params: { assignment: { name: 'Updated Name' } }, as: :json
      expect(response).to have_http_status(:ok)
      assignment.reload
      expect(assignment.name).to eq('Updated Name')
    end
  end

  describe 'DELETE /api/v1/assignments/:id' do
    it 'deletes an assignment' do
      DueDate.where(parent: assignment).delete_all
      expect {
        delete "/api/v1/assignments/#{assignment.id}"
      }.to change(Assignment, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
