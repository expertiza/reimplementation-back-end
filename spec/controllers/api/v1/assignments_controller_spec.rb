require 'rails_helper'

RSpec.describe Api::V1::AssignmentsController, type: :controller do
  let(:valid_attributes) { { title: 'Test Assignment', description: 'Test Description' } }
  let(:invalid_attributes) { { title: nil, description: 'Test Description' } }
  let!(:assignment) { Assignment.create!(valid_attributes) }

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response for a valid assignment" do
      get :show, params: { id: assignment.to_param }
      expect(response).to be_successful
    end

    it "returns a not found response for an invalid assignment" do
      get :show, params: { id: 'invalid' }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Assignment" do
        expect {
          post :create, params: { assignment: valid_attributes }
        }.to change(Assignment, :count).by(1)
      end

      it "renders a JSON response with the new assignment" do
        post :create, params: { assignment: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new assignment" do
        post :create, params: { assignment: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) { { title: 'Updated Title' } }

      it "updates the requested assignment" do
        put :update, params: { id: assignment.to_param, assignment: new_attributes }
        assignment.reload
        expect(assignment.title).to eq('Updated Title')
      end

      it "renders a JSON response with the assignment" do
        put :update, params: { id: assignment.to_param, assignment: valid_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the assignment" do
        put :update, params: { id: assignment.to_param, assignment: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested assignment" do
      expect {
        delete :destroy, params: { id: assignment.to_param }
      }.to change(Assignment, :count).by(-1)
    end

    it "renders a JSON response with the success message" do
      delete :destroy, params: { id: assignment.to_param }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(a_string_including("application/json"))
    end
  end
end
