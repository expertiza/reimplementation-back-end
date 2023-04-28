require 'rails_helper'

RSpec.describe "Api::V1::Duties", type: :request do
  let(:user) { create(:user) }
  let(:assignment) { build(:assignment, id: 1) }
  let(:due_date) { build(:assignment_due_date, deadline_type_id: 1) }
  describe "GET #index" do
    it "returns http success" do
      get "/api/v1/duties"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      duty = Duty.create(name: "Test Duties", max_members_for_duty: 1)
      get "/api/v1/duties/#{duty.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "returns http success" do
      assignment = Assignment.create(name: "Assignment")
      post "/api/v1/duties", params: { duty: { name: "Test Duty", max_members_for_duty: 1, assignment_id: assignment.id} }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /update" do
    it "returns http success" do
      assignment = Assignment.create(name: "Assignment")
      duty = Duty.create(name: "Test Duty", max_members_for_duty: 1, assignment_id: assignment.id)
      patch "/api/v1/duties/#{duty.id}", params: { duty: { name: "New Test Duty Name" } }
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /destroy" do
    it "returns http success" do
      assignment = Assignment.create(name: "Assignment")
      duty = Duty.create(name: "Test Duty", max_members_for_duty: 1, assignment_id: assignment.id)
      delete "/api/v1/duties/#{duty.id}"
      expect(response).to have_http_status(:redirect)
    end
  end


end
