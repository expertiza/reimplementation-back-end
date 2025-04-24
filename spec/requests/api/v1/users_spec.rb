require 'rails_helper'
require Rails.root.join("lib/json_web_token.rb")

RSpec.describe "Users API", type: :request do
  let!(:user) { create(:user, password: "bruh1234", password_confirmation: "bruh1234") }
  let!(:token) do
    payload = {
      id: user.id,
      name: user.name,
      full_name: user.full_name,
      role: user.role.name,
      institution_id: user.institution&.id,
      jwt_version: user.jwt_version
    }
    JsonWebToken.encode(payload, 24.hours.from_now)
  end

  let(:headers) { { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json" } }

  describe "GET /api/v1/users/:id/get_profile" do
    it "returns the user profile" do
      get "/api/v1/users/#{user.id}/get_profile", headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("full_name" => user.full_name)
    end
  end

  describe "PATCH /api/v1/users/:id/update_profile" do
    it "updates the user profile successfully" do
      patch "/api/v1/users/#{user.id}/update_profile",
            params: {
              user: {
                full_name: "Updated Name",
                email: "new@example.com",
                language: "English",
                time_zone: "GMT+01:00"
              }
            }.to_json,
            headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["user"]["full_name"]).to eq("Updated Name")
    end
  end

  describe "POST /api/v1/users/:id/update_password" do
    it "updates the password and returns new token" do
      post "/api/v1/users/#{user.id}/update_password",
           params: {
             password: "newpassword123",
             confirmPassword: "newpassword123"
           }.to_json,
           headers: headers

      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json).to have_key("token")
      expect(json["message"]).to eq("Password updated successfully")
    end

    it "returns error if passwords do not match" do
      post "/api/v1/users/#{user.id}/update_password",
           params: {
             password: "onepassword",
             confirmPassword: "otherpassword"
           }.to_json,
           headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("Passwords do not match")
    end
  end
end
