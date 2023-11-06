require 'rails_helper'

describe Api::V1::BadgesController, type: :controller do
  describe "index" do
    it "returns all badges" do
      # Test scenario: When there are no badges in the database initially.
      get :index
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([]) # Use JSON.parse for comparing JSON responses.
    end

    it "returns a successful response status" do
      # Test scenario: When there is an error in retrieving badges.
      # Expected behavior: The response status should indicate an error.
      allow(Badge).to receive(:all).and_raise(StandardError, 'Database connection error')
      get :index
      expect(response).to have_http_status(:error) # Adjust this to the actual error status code.
    end
  end

  describe "show" do
    it "returns a specific badge" do
      # Test scenario: When a badge with a valid ID is requested.
      badge = Badge.create(name: 'Test Badge')
      get :show, params: { id: badge.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('name' => 'Test Badge')
    end

    it "returns an error message for a non-existent badge" do
      # Test scenario: When a badge with an invalid ID is requested.
      get :show, params: { id: 9999 } # Assuming 9999 is an invalid badge ID.
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_empty
    end
  end

  describe "create" do
    it "creates a new badge" do
      # Test scenario: Creating a new badge with valid parameters.
      post :create, params: { badge: { name: 'New Badge' } }
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)).to include('name' => 'New Badge')
    end

    it "returns an error message for invalid badge parameters" do
      # Test scenario: Creating a new badge with invalid parameters (empty name).
      post :create, params: { badge: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include('name' => ["can't be blank"])
    end
  end

  describe "update" do
    it "updates an existing badge" do
      # Test scenario: Updating an existing badge with valid parameters.
      badge = Badge.create(name: 'Old Badge')
      patch :update, params: { id: badge.id, badge: { name: 'Updated Badge' } }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('name' => 'Updated Badge')
    end

    it "returns an error message for invalid badge parameters" do
      # Test scenario: Updating an existing badge with invalid parameters (empty name).
      badge = Badge.create(name: 'Old Badge')
      patch :update, params: { id: badge.id, badge: { name: '' } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to include('name' => ["can't be blank"])
    end
  end

  describe "destroy" do
    it "destroys an existing badge" do
      # Test scenario: Destroying an existing badge.
      badge = Badge.create(name: 'Badge to be Destroyed')
      delete :destroy, params: { id: badge.id }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('message' => 'Badge was successfully destroyed.')
    end

    it "returns an error message for a non-existent badge" do
      # Test scenario: Attempting to destroy a non-existent badge.
      delete :destroy, params: { id: 9999 } # Assuming 9999 is an invalid badge ID.
      expect(response).to have_http_status(:not_found)
    end
  end
end
