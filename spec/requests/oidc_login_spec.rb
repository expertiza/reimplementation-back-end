require 'rails_helper'

RSpec.describe "OidcLogins", type: :request do
  describe "GET /providers" do
    it "returns http success" do
      get "/oidc_login/providers"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /client_select" do
    it "returns http success" do
      get "/oidc_login/client_select"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /callback" do
    it "returns http success" do
      get "/oidc_login/callback"
      expect(response).to have_http_status(:success)
    end
  end

end
