require 'rails_helper'

RSpec.describe Api::V1::ParticipantsController, type: :controller do
  let!(:participant) { create(:participant) } 

  describe "GET #index" do
    it "returns a successful response" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:participants)).to eq([participant])
    end
  end

  describe "GET #show" do
    context "when the participant exists" do
      it "returns the participant" do
        get :show, params: { id: participant.id }
        expect(response).to have_http_status(:ok)
        expect(assigns(:participant)).to eq(participant)
      end
    end

    context "when the participant does not exist" do
      it "returns a not found status" do
        get :show, params: { id: -1 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new participant" do
        expect {
          post :create, params: { participant: attributes_for(:participant) }
        }.to change(Participant, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end

    context "with invalid parameters" do
      it "does not create a new participant" do
        expect {
          post :create, params: { participant: { user_id: nil } } 
        }.to change(Participant, :count).by(0)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET #edit" do
    it "returns a successful response" do
      get :edit, params: { id: participant.id }
      expect(response).to be_successful
    end
  end

  describe "PATCH/PUT #update" do
    context "with valid parameters" do
      it "updates the participant" do
        patch :update, params: { id: participant.id, participant: { type: "NewType" } }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid parameters" do
      it "does not update the participant" do
        patch :update, params: { id: participant.id, participant: { user_id: nil } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #destroy" do
    it "deletes the participant" do
      delete :destroy, params: { id: participant.id }
      expect(response).to have_http_status(:ok)
      expect(Participant.exists?(participant.id)).to be(false)
    end
  end

  describe "#participant_assignment" do
    context "when participant exists" do
      it "returns the assignment of the participant" do
        get :participant_assignment, params: { participant_id: participant.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when participant does not exist" do
      it "returns not found status" do
        get :participant_assignment, params: { participant_id: -1 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

end
