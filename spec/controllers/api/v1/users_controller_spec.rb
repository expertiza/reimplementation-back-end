require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  let!(:user) { User.create(name: "John Doe", email: "john@example.com", password: "password123") }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
    end
  end

  describe "GET #show" do
    context "when user exists" do
      it "returns the user" do
        get :show, params: { id: user.id }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["id"]).to eq(user.id)
        expect(json_response["name"]).to eq(user.name)
      end
    end

    context "when user does not exist" do
      it "returns a 404 error" do
        get :show, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User not found")
      end
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post :create, params: { user: { name: "Alice", email: "alice@example.com", password: "password" } }
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["name"]).to eq("Alice")
      end
    end

    context "with invalid parameters" do
      it "returns errors" do
        post :create, params: { user: { name: "", email: "", password: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).not_to be_empty
      end
    end
  end

  describe "PUT #update" do
    context "with valid parameters" do
      it "updates the user" do
        put :update, params: { id: user.id, user: { name: "Updated Name" } }
        expect(response).to have_http_status(:ok)
        user.reload
        expect(user.name).to eq("Updated Name")
      end
    end

    context "with invalid parameters" do
      it "returns errors" do
        put :update, params: { id: user.id, user: { email: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).not_to be_empty
      end
    end
  end

  describe "DELETE #destroy" do
    context "when user exists" do
      it "deletes the user" do
        expect {
          delete :destroy, params: { id: user.id }
        }.to change(User, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end

    context "when user does not exist" do
      it "returns 404 error" do
        delete :destroy, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User not found")
      end
    end
  end
end
