require 'rails_helper'

RSpec.describe "Api::V1::Badges", type: :request do
  let(:user) { create(:user) }

  describe "GET #index" do
    it "returns http success" do
      get "/api/v1/badges"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      badge = Badge.create(name: "Test Badge", description: "This is a test badge")
      get "/api/v1/badges/#{badge.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "returns http success" do
      post "/api/v1/badges", params: { badge: { name: "Test Badge", description: "This is a test badge" } }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /update" do
    it "returns http success" do
      badge = Badge.create(name: "Test Badge", description: "This is a test badge")
      patch "/api/v1/badges/#{badge.id}", params: { badge: { name: "New Test Badge Name" } }
      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /destroy" do
    it "returns http success" do
      badge = Badge.create(name: "Test Badge", description: "This is a test badge")
      delete "/api/v1/badges/#{badge.id}"
      expect(response).to have_http_status(:redirect)
    end
  end


end
