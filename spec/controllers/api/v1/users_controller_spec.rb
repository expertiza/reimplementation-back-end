require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  # Disable authentication for tests
  before { allow(controller).to receive(:authenticate_user!).and_return(true) }

  let!(:user) { User.create(name: "John Doe", email: "john@example.com", password: "password123") }

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates a new user" do
      post :create, params: { user: { name: "Alice", email: "alice@example.com", password: "password" } }
      expect(response).to have_http_status(:created)
      expect(User.last.name).to eq("Alice")
    end
  end
end

