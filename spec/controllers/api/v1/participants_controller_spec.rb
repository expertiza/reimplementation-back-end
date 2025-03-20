require 'rails_helper'

RSpec.describe Api::V1::ParticipantsController, type: :controller do
  let!(:user) { create(:user) }  
  let!(:assignment) { create(:assignment) }  
  let!(:participant) { create(:participant, user: user, assignment: assignment) }  

  
  describe 'GET #list_user_participants' do
    context 'when user exists' do
      it 'returns a list of participants' do
        get :list_user_participants, params: { user_id: user.id }
        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([participant.as_json])
      end
    end

    context 'when user does not exist' do
      it 'returns an error' do
        get :list_user_participants, params: { user_id: 99999 }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('User not found')
      end
    end
  end

  
  describe 'GET #list_assignment_participants' do
    context 'when assignment exists' do
      it 'returns a list of participants' do
        get :list_assignment_participants, params: { assignment_id: assignment.id }
        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([participant.as_json])
      end
    end

    context 'when assignment does not exist' do
      it 'returns an error' do
        get :list_assignment_participants, params: { assignment_id: 99999 }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Assignment not found')
      end
    end
  end

  
  describe 'GET #show' do
    context 'when participant exists' do
      it 'returns the participant' do
        get :show, params: { id: participant.id }
        expect(response).to have_http_status(:created)  # The controller uses :created for this response
        expect(json_response).to eq(participant.as_json)
      end
    end

    context 'when participant does not exist' do
      it 'returns an error' do
        get :show, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Participant not found')
      end
    end
  end

  
  describe 'POST #add' do
    context 'with valid parameters' do
      let(:valid_params) { { user_id: user.id, assignment_id: assignment.id, authorization: 'submitter' } }

      it 'adds the participant and returns a successful response' do
        post :add, params: valid_params
        expect(response).to have_http_status(:created)
        expect(json_response['user_id']).to eq(user.id)
        expect(json_response['assignment_id']).to eq(assignment.id)
      end
    end

    context 'with invalid parameters' do
      it 'returns an error when user is not found' do
        post :add, params: { user_id: 99999, assignment_id: assignment.id, authorization: 'submitter' }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('User not found')
      end

      it 'returns an error when assignment is not found' do
        post :add, params: { user_id: user.id, assignment_id: 99999, authorization: 'submitter' }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Assignment not found')
      end

      it 'returns an error when authorization is invalid' do
        post :add, params: { user_id: user.id, assignment_id: assignment.id, authorization: 'invalid' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('authorization not valid. Valid authorizations are: Reader, Reviewer, Submitter, Mentor')
      end
    end
  end

  
  describe 'PATCH #update_authorization' do
    let(:new_authorization) { 'reviewer' }

    context 'with valid authorization' do
      it 'updates the participant authorization' do
        patch :update_authorization, params: { id: participant.id, authorization: new_authorization }
        participant.reload
        expect(response).to have_http_status(:created)
        expect(participant.authorization).to eq(new_authorization)
      end
    end

    context 'with invalid authorization' do
      it 'returns an error' do
        patch :update_authorization, params: { id: participant.id, authorization: 'invalid' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('authorization not valid. Valid authorizations are: Reader, Reviewer, Submitter, Mentor')
      end
    end
  end

  
  describe 'DELETE #destroy' do
    context 'when participant exists' do
      it 'deletes the participant and returns a success message' do
        delete :destroy, params: { id: participant.id }
        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq("Participant #{participant.id} in Assignment #{assignment.id} has been deleted successfully!")
      end
    end

    context 'when participant does not exist' do
      it 'returns an error' do
        delete :destroy, params: { id: 99999 }
        expect(response).to have_http_status(:not_found)
        expect(json_response['error']).to eq('Not Found')
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end