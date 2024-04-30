# spec/controllers/api/v1/assignments_controller_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::AssignmentsController, type: :controller do
  describe "GET #index" do
    it "returns a success response" do
      assignment = create(:assignment)
      get :index
      expect(response).to be_successful
      expect(response.content_type).to eq("application/json; charset=utf-8")
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe "GET #show" do
    it "returns the requested assignment" do
      assignment = create(:assignment)
      get :show, params: { id: assignment.id }
      expect(response).to be_successful
      expect(JSON.parse(response.body)["id"]).to eq(assignment.id)
    end

    it "returns an error for a non-existent assignment" do
      get :show, params: { id: 10000 } # assuming no assignment has this ID
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new Assignment" do
        expect {
          post :create, params: { assignment: attributes_for(:assignment) }
        }.to change(Assignment, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      it "returns an error" do
        post :create, params: { assignment: { name: '' } } # invalid attributes
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #update" do
    let(:assignment) { create(:assignment) }
    context "with valid parameters" do
      it "updates the requested assignment" do
        patch :update, params: { id: assignment.id, assignment: { name: "Updated Name" } }
        assignment.reload
        expect(assignment.name).to eq("Updated Name")
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid parameters" do
      it "returns an error" do
        patch :update, params: { id: assignment.id, assignment: { name: '' } } # empty name
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:assignment) { create(:assignment) }
    it "destroys the requested assignment" do
      expect {
        delete :destroy, params: { id: assignment.id }
      }.to change(Assignment, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
