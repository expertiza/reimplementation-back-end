require 'rails_helper'

RSpec.describe Api::V1::AssignmentsController, type: :controller do
  # Setup required data
  let!(:instructor) { User.create!(name: "Instructor", email: "instructor@example.com", password: "password123") }
  let!(:course) { Course.create!(title: "Sample Course", description: "Course Desc") }

  let!(:assignment) do
    Assignment.create!(
      name: "Sample Assignment",
      description: "Assignment Desc",
      due_date: "2025-12-31",
      instructor_id: instructor.id,
      course_id: course.id,
      max_team_size: 2
    )
  end

  # Stub authentication
  before do
    allow_any_instance_of(Api::V1::AssignmentsController).to receive(:authenticate_user!).and_return(true)
  end

  describe 'GET #index' do
    it 'returns all assignments' do
      get :index
      expect(response).to have_http_status(:ok)
      parsed = JSON.parse(response.body)
      expect(parsed.first['name']).to eq('Sample Assignment')
    end
  end

  describe 'GET #show' do
    it 'returns a specific assignment' do
      get :show, params: { id: assignment.id }
      expect(response).to have_http_status(:ok)
      parsed = JSON.parse(response.body)
      expect(parsed['id']).to eq(assignment.id)
    end
  end

  describe 'POST #create' do
    it 'creates a new assignment' do
      expect {
        post :create, params: { assignment: { name: 'New Assignment', description: 'Desc', due_date: '2025-12-31', instructor_id: instructor.id, course_id: course.id, max_team_size: 3 } }
      }.to change(Assignment, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end

  describe 'PUT #update' do
    it 'updates an assignment' do
      put :update, params: { id: assignment.id, assignment: { name: 'Updated Assignment' } }
      expect(response).to have_http_status(:ok)
      assignment.reload
      expect(assignment.name).to eq('Updated Assignment')
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes an assignment' do
      expect {
        delete :destroy, params: { id: assignment.id }
      }.to change(Assignment, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
