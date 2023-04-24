require 'rails_helper'

RSpec.describe "Api::V1::Badges", type: :request do
  let(:user) { create(:user) }

  describe "GET #index" do
    it "returns http success" do
      get "/api/v1/badges/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/v1/badges/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/badges/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/api/v1/badges/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/api/v1/badges/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
