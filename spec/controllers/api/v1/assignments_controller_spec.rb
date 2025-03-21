# spec/controllers/api/v1/assignments_controller_spec.rb

require 'rails_helper'

RSpec.describe Api::V1::AssignmentsController, type: :controller do
  describe 'GET #index' do
    it 'returns a successful response' do
      get :index, format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'returns all assignments as JSON' do
      assignment1 = create(:assignment, title: 'Assignment 1')
      assignment2 = create(:assignment, title: 'Assignment 2')

      get :index, format: :json
      json_response = JSON.parse(response.body)

      expect(json_response.size).to eq(2)
      expect(json_response.map { |a| a['title'] }).to match_array(['Assignment 1', 'Assignment 2'])
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      assignment = create(:assignment)
      get :show, params: { id: assignment.id }, format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'returns the requested assignment as JSON' do
      assignment = create(:assignment, title: 'Specific Assignment')
      get :show, params: { id: assignment.id }, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response['title']).to eq('Specific Assignment')
    end

    it 'returns a 404 if the assignment is not found' do
      get :show, params: { id: 999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST #create' do
    it 'creates a new assignment' do
      expect {
        post :create, params: { assignment: attributes_for(:assignment) }, format: :json
      }.to change(Assignment, :count).by(1)
    end

    it 'returns the created assignment as JSON' do
      post :create, params: { assignment: attributes_for(:assignment, title: 'New Assignment') }, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response['title']).to eq('New Assignment')
    end

    it 'returns a 422 if the assignment is invalid' do
      post :create, params: { assignment: { title: nil } }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT #update' do
    it 'updates the assignment' do
      assignment = create(:assignment, title: 'Original Title')
      put :update, params: { id: assignment.id, assignment: { title: 'Updated Title' } }, format: :json
      assignment.reload
      expect(assignment.title).to eq('Updated Title')
    end

    it 'returns the updated assignment as JSON' do
      assignment = create(:assignment)
      put :update, params: { id: assignment.id, assignment: { title: 'Updated Title' } }, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response['title']).to eq('Updated Title')
    end

    it 'returns a 422 if the assignment is invalid' do
      assignment = create(:assignment)
      put :update, params: { id: assignment.id, assignment: { title: nil } }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns a 404 if the assignment is not found' do
      put :update, params: { id: 999, assignment: { title: 'Updated Title' } }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    it 'deletes the assignment' do
      assignment = create(:assignment)
      expect {
        delete :destroy, params: { id: assignment.id }, format: :json
      }.to change(Assignment, :count).by(-1)
    end

    it 'returns a 204 after successful deletion' do
      assignment = create(:assignment)
      delete :destroy, params: { id: assignment.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end

    it 'returns a 404 if the assignment is not found' do
      delete :destroy, params: { id: 999 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
