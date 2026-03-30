# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe ResponseMapsController, type: :controller do
  before do
    allow(controller).to receive(:authenticate_request!).and_return(true)
    allow_any_instance_of(Authorization).to receive(:authorize).and_return(true)
  end

  let(:assignment) { create(:assignment) }
  let(:reviewer)   { create(:assignment_participant, assignment: assignment) }
  let(:reviewee)   { create(:assignment_participant, assignment: assignment) }

  let!(:response_map) do
    ResponseMap.create!(
      reviewer_id: reviewer.id,
      reviewee_id: reviewee.id,
      reviewed_object_id: assignment.id
    )
  end

  # ─── GET #show ──────────────────────────────────────────────────────────────

  describe 'GET #show' do
    context 'when the response map exists' do
      it 'returns HTTP 200' do
        get :show, params: { id: response_map.id }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns the correct response map id' do
        get :show, params: { id: response_map.id }, format: :json
        expect(JSON.parse(response.body)['id']).to eq(response_map.id)
      end

      it 'returns correct reviewer_id, reviewee_id, and reviewed_object_id' do
        get :show, params: { id: response_map.id }, format: :json
        data = JSON.parse(response.body)
        expect(data['reviewer_id']).to eq(reviewer.id)
        expect(data['reviewee_id']).to eq(reviewee.id)
        expect(data['reviewed_object_id']).to eq(assignment.id)
      end
    end

    context 'when the response map does not exist' do
      it 'returns HTTP 404' do
        get :show, params: { id: 99_999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error message' do
        get :show, params: { id: 99_999 }, format: :json
        expect(JSON.parse(response.body)['error']).to eq('Response map not found')
      end
    end
  end

  # ─── POST #create ────────────────────────────────────────────────────────────

  describe 'POST #create' do
    let(:valid_params) do
      {
        response_map: {
          reviewer_id: reviewer.id,
          reviewee_id: reviewee.id,
          reviewed_object_id: assignment.id
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new ResponseMap record' do
        expect do
          post :create, params: valid_params, format: :json
        end.to change(ResponseMap, :count).by(1)
      end

      it 'returns HTTP 201' do
        post :create, params: valid_params, format: :json
        expect(response).to have_http_status(:created)
      end

      it 'persists correct reviewer_id and reviewee_id to the database' do
        post :create, params: valid_params, format: :json
        created = ResponseMap.last
        expect(created.reviewer_id).to eq(reviewer.id)
        expect(created.reviewee_id).to eq(reviewee.id)
        expect(created.reviewed_object_id).to eq(assignment.id)
      end
    end

    context 'with missing reviewer_id' do
      it 'does not create a record and returns HTTP 422' do
        expect do
          post :create,
               params: { response_map: { reviewee_id: reviewee.id, reviewed_object_id: assignment.id } },
               format: :json
        end.not_to change(ResponseMap, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with missing reviewee_id' do
      it 'does not create a record and returns HTTP 422' do
        expect do
          post :create,
               params: { response_map: { reviewer_id: reviewer.id, reviewed_object_id: assignment.id } },
               format: :json
        end.not_to change(ResponseMap, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with all required parameters nil' do
      it 'does not create a record and returns HTTP 422' do
        expect do
          post :create,
               params: { response_map: { reviewer_id: nil, reviewee_id: nil, reviewed_object_id: nil } },
               format: :json
        end.not_to change(ResponseMap, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ─── PATCH #update ───────────────────────────────────────────────────────────

  describe 'PATCH #update' do
    let(:new_reviewee) { create(:assignment_participant, assignment: assignment) }

    context 'when the response map exists and parameters are valid' do
      it 'returns HTTP 200' do
        patch :update,
              params: { id: response_map.id, response_map: { reviewee_id: new_reviewee.id } },
              format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'persists the updated reviewee_id' do
        patch :update,
              params: { id: response_map.id, response_map: { reviewee_id: new_reviewee.id } },
              format: :json
        expect(response_map.reload.reviewee_id).to eq(new_reviewee.id)
      end
    end

    context 'when the response map does not exist' do
      it 'returns HTTP 404' do
        patch :update,
              params: { id: 99_999, response_map: { reviewee_id: new_reviewee.id } },
              format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error message' do
        patch :update,
              params: { id: 99_999, response_map: { reviewee_id: new_reviewee.id } },
              format: :json
        expect(JSON.parse(response.body)['error']).to eq('Response map not found')
      end
    end
  end

  # ─── DELETE #destroy ─────────────────────────────────────────────────────────

  describe 'DELETE #destroy' do
    context 'when the response map exists' do
      it 'destroys the record' do
        expect do
          delete :destroy, params: { id: response_map.id }, format: :json
        end.to change(ResponseMap, :count).by(-1)
      end

      it 'returns HTTP 204' do
        delete :destroy, params: { id: response_map.id }, format: :json
        expect(response).to have_http_status(:no_content)
      end

      it 'returns an empty body' do
        delete :destroy, params: { id: response_map.id }, format: :json
        expect(response.body).to be_empty
      end

      it 'makes the record unfindable afterward' do
        delete :destroy, params: { id: response_map.id }, format: :json
        expect(ResponseMap.find_by(id: response_map.id)).to be_nil
      end
    end

    context 'when the response map does not exist' do
      it 'returns HTTP 404' do
        delete :destroy, params: { id: 99_999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns an error message' do
        delete :destroy, params: { id: 99_999 }, format: :json
        expect(JSON.parse(response.body)['error']).to eq('Response map not found')
      end
    end
  end

  # ─── GET #fetch_response_maps_for_assignment ─────────────────────────────────

  describe 'GET #fetch_response_maps_for_assignment' do
    context 'when response maps exist for the assignment' do
      it 'returns HTTP 200' do
        get :fetch_response_maps_for_assignment, params: { assignment_id: assignment.id }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns an array of response maps' do
        get :fetch_response_maps_for_assignment, params: { assignment_id: assignment.id }, format: :json
        expect(JSON.parse(response.body)).to be_an(Array)
      end

      it 'returns only maps belonging to the given assignment' do
        get :fetch_response_maps_for_assignment, params: { assignment_id: assignment.id }, format: :json
        ids = JSON.parse(response.body).map { |rm| rm['reviewed_object_id'] }
        expect(ids).to all(eq(assignment.id))
      end

      it 'returns multiple maps when several exist for the assignment' do
        extra_reviewee = create(:assignment_participant, assignment: assignment)
        ResponseMap.create!(
          reviewer_id: reviewer.id,
          reviewee_id: extra_reviewee.id,
          reviewed_object_id: assignment.id
        )
        get :fetch_response_maps_for_assignment, params: { assignment_id: assignment.id }, format: :json
        expect(JSON.parse(response.body).length).to eq(2)
      end
    end

    context 'when no response maps exist for the assignment' do
      it 'returns HTTP 200 with an empty array' do
        get :fetch_response_maps_for_assignment, params: { assignment_id: 99_999 }, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  # ─── GET #fetch_response_maps_for_reviewer ───────────────────────────────────

  describe 'GET #fetch_response_maps_for_reviewer' do
    context 'when response maps exist for the reviewer' do
      it 'returns HTTP 200' do
        get :fetch_response_maps_for_reviewer, params: { reviewer_id: reviewer.id }, format: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns an array of response maps' do
        get :fetch_response_maps_for_reviewer, params: { reviewer_id: reviewer.id }, format: :json
        expect(JSON.parse(response.body)).to be_an(Array)
      end

      it 'returns only maps belonging to the given reviewer' do
        get :fetch_response_maps_for_reviewer, params: { reviewer_id: reviewer.id }, format: :json
        ids = JSON.parse(response.body).map { |rm| rm['reviewer_id'] }
        expect(ids).to all(eq(reviewer.id))
      end

      it 'returns all maps when the reviewer has multiple' do
        extra_reviewee = create(:assignment_participant, assignment: assignment)
        ResponseMap.create!(
          reviewer_id: reviewer.id,
          reviewee_id: extra_reviewee.id,
          reviewed_object_id: assignment.id
        )
        get :fetch_response_maps_for_reviewer, params: { reviewer_id: reviewer.id }, format: :json
        expect(JSON.parse(response.body).length).to eq(2)
      end
    end

    context 'when no response maps exist for the reviewer' do
      it 'returns HTTP 200 with an empty array' do
        get :fetch_response_maps_for_reviewer, params: { reviewer_id: 99_999 }, format: :json
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq([])
      end
    end
  end

  # ─── GET #response_rate ──────────────────────────────────────────────────────

  describe 'GET #response_rate' do
    context 'response body structure' do
      it 'includes total_response_maps, completed_response_maps, and response_rate' do
        get :response_rate, params: { assignment_id: assignment.id }, format: :json
        data = JSON.parse(response.body)
        expect(data).to have_key('total_response_maps')
        expect(data).to have_key('completed_response_maps')
        expect(data).to have_key('response_rate')
      end
    end

    context 'when no response maps exist for the assignment' do
      it 'returns zero for all stats' do
        get :response_rate, params: { assignment_id: 99_999 }, format: :json
        data = JSON.parse(response.body)
        expect(data['total_response_maps']).to eq(0)
        expect(data['completed_response_maps']).to eq(0)
        expect(data['response_rate']).to eq(0)
      end
    end

    context 'when maps exist but none have submitted responses' do
      it 'returns total count with 0 completed and 0.0% rate' do
        get :response_rate, params: { assignment_id: assignment.id }, format: :json
        data = JSON.parse(response.body)
        expect(data['total_response_maps']).to eq(1)
        expect(data['completed_response_maps']).to eq(0)
        expect(data['response_rate']).to eq(0.0)
      end
    end

    context 'when a response exists but is_submitted is false' do
      before { Response.create!(map_id: response_map.id, is_submitted: false) }

      it 'does not count unsubmitted responses as completed' do
        get :response_rate, params: { assignment_id: assignment.id }, format: :json
        data = JSON.parse(response.body)
        expect(data['completed_response_maps']).to eq(0)
        expect(data['response_rate']).to eq(0.0)
      end
    end

    context 'when all maps have submitted responses' do
      before { Response.create!(map_id: response_map.id, is_submitted: true) }

      it 'returns 100% response rate' do
        get :response_rate, params: { assignment_id: assignment.id }, format: :json
        data = JSON.parse(response.body)
        expect(data['total_response_maps']).to eq(1)
        expect(data['completed_response_maps']).to eq(1)
        expect(data['response_rate']).to eq(100.0)
      end
    end

    context 'when only some maps are completed' do
      before do
        extra_reviewee = create(:assignment_participant, assignment: assignment)
        ResponseMap.create!(
          reviewer_id: reviewer.id,
          reviewee_id: extra_reviewee.id,
          reviewed_object_id: assignment.id
        )
        Response.create!(map_id: response_map.id, is_submitted: true)
      end

      it 'returns 50% response rate' do
        get :response_rate, params: { assignment_id: assignment.id }, format: :json
        data = JSON.parse(response.body)
        expect(data['total_response_maps']).to eq(2)
        expect(data['completed_response_maps']).to eq(1)
        expect(data['response_rate']).to eq(50.0)
      end
    end

    context 'when a map has multiple responses but only one is submitted' do
      before do
        Response.create!(map_id: response_map.id, is_submitted: false)
        Response.create!(map_id: response_map.id, is_submitted: true)
      end

      it 'counts the map as completed only once (no double-counting)' do
        get :response_rate, params: { assignment_id: assignment.id }, format: :json
        data = JSON.parse(response.body)
        expect(data['total_response_maps']).to eq(1)
        expect(data['completed_response_maps']).to eq(1)
        expect(data['response_rate']).to eq(100.0)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
