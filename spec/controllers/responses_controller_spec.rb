# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponsesController, type: :controller do
  let(:user) { instance_double('User', id: 10) }

  before do
    # Prevent before_action from blocking tests: stub the authorize before_action defined in ApplicationController
    allow(controller).to receive(:authorize).and_return(true)

    # Provide a current_user for controller methods that rely on it
    # Set a fake Authorization header and stub token decoding + User.find so authenticate_request! succeeds without DB
    request.headers['Authorization'] = 'Bearer faketoken'
    allow(JsonWebToken).to receive(:decode).and_return({ id: user.id })
    allow(User).to receive(:find).with(user.id).and_return(user)
    # Note: not stubbing authenticate_request! so the controller's JwtToken behavior runs but uses the above stubs

    # Also provide current_user directly to be safe
    allow(controller).to receive(:current_user).and_return(user)

    # Stub role helpers used by ResponsesController
    allow(controller).to receive(:has_role?).and_return(true)
    allow(controller).to receive(:action_allowed?).and_return(true)
  end

  describe 'POST #create' do
    let(:response_map) { double('ResponseMap', id: 123) }
    let(:response_double) { double('Response') }

    before do
      allow(ResponseMap).to receive(:find_by).and_return(response_map)
      allow(Response).to receive(:new).and_return(response_double)
      allow(response_double).to receive(:as_json).and_return({ 'id' => 1 })
    end

    context 'when save succeeds' do
      before do
        allow(response_double).to receive(:save).and_return(true)
      end

      it 'creates a draft and returns 201' do
        expect(Response).to receive(:new).with(hash_including(map_id: response_map.id, is_submitted: false))
        post :create, params: { response_map_id: response_map.id }
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body['message']).to eq('Response draft created successfully')
        expect(body['response']).to eq({ 'id' => 1 })
      end
    end

    context 'when save fails' do
      before do
        allow(response_double).to receive(:save).and_return(false)
        allow(response_double).to receive_message_chain(:errors, :full_messages).and_return(['err'])
      end

      it 'returns 422 with error message' do
        post :create, params: { response_map_id: response_map.id }
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to include('err')
      end
    end

    context 'when response_map not found' do
      before do
        allow(ResponseMap).to receive(:find_by).and_return(nil)
      end

      it 'returns 404' do
        post :create, params: { response_map_id: 9999 }
        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('ResponseMap not found')
      end
    end
  end

  describe 'PATCH #update' do
    let(:response_double) { double('Response') }

    before do
      allow(controller).to receive(:set_response) { controller.instance_variable_set(:@response, response_double) }
      allow(response_double).to receive(:update)
    end

    context 'when response already submitted' do
      before do
        allow(response_double).to receive(:is_submitted?).and_return(true)
      end

      it 'returns forbidden' do
        patch :update, params: { id: 1, response: { content: 'x' } }
        expect(response).to have_http_status(:forbidden)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('forbidden')
      end
    end

    context 'when update succeeds' do
      before do
        allow(response_double).to receive(:is_submitted?).and_return(false)
        allow(response_double).to receive(:update).and_return(true)
      end

      it 'returns ok and success message' do
        patch :update, params: { id: 1, response: { content: 'x' } }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['message']).to eq('Draft updated successfully')
      end
    end

    context 'when update fails' do
      before do
        allow(response_double).to receive(:is_submitted?).and_return(false)
        allow(response_double).to receive(:update).and_return(false)
        allow(response_double).to receive_message_chain(:errors, :full_messages).and_return(['bad'])
      end

      it 'returns unprocessable_entity with errors' do
        patch :update, params: { id: 1, response: { content: 'x' } }
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to include('bad')
      end
    end
  end

  describe 'PATCH #submit' do
    let(:response_double) { double('Response') }

    before do
      allow(controller).to receive(:set_response) { controller.instance_variable_set(:@response, response_double) }
    end

    context 'when response not found' do
      before do
        allow(controller).to receive(:set_response) { controller.instance_variable_set(:@response, nil) }
      end

      it 'returns 404' do
        patch :submit, params: { id: 1 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when already submitted' do
      before do
        allow(response_double).to receive(:is_submitted?).and_return(true)
      end

      it 'returns 422 with already submitted message' do
        patch :submit, params: { id: 1 }
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Response already submitted')
      end
    end

    context 'when rubric incomplete' do
      before do
        allow(response_double).to receive(:is_submitted?).and_return(false)
        allow(response_double).to receive(:scores).and_return([double('Score', answer: nil)])
      end

      it 'returns 422 with rubric error' do
        patch :submit, params: { id: 1 }
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('All rubric items must be answered')
      end
    end

    context 'when deadline has passed' do
      before do
        allow(response_double).to receive(:is_submitted?).and_return(false)
        allow(controller).to receive(:deadline_open?).with(response_double).and_return(false)
      end

      it 'returns forbidden with deadline message' do
        patch :submit, params: { id: 1 }
        expect(response).to have_http_status(:forbidden)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Deadline has passed')
      end
    end

    context 'when submitting twice (duplicate submission)' do
      before do
        # first call: not submitted, second call: already submitted
        allow(response_double).to receive(:is_submitted?).and_return(false, true)
        allow(response_double).to receive(:scores).and_return([])
        allow(response_double).to receive(:aggregate_questionnaire_score).and_return(42)
        allow(response_double).to receive(:save).and_return(true)
        allow(response_double).to receive(:as_json).and_return({ 'id' => 99 })
        allow(response_double).to receive(:is_submitted=).with(true)
        allow(response_double).to receive(:submitted_at=)
      end

      it 'allows the first submission and rejects the second' do
        patch :submit, params: { id: 1 }
        expect(response).to have_http_status(:ok)

        # second attempt should be blocked as already submitted
        patch :submit, params: { id: 1 }
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Response already submitted')
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:response_double) { double('Response') }

    before do
      allow(controller).to receive(:set_response) { controller.instance_variable_set(:@response, response_double) }
    end

    context 'when response not found' do
      before do
        allow(controller).to receive(:set_response) { controller.instance_variable_set(:@response, nil) }
      end

      it 'returns 404' do
        delete :destroy, params: { id: 1 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when destroy succeeds' do
      before do
        allow(response_double).to receive(:destroy).and_return(true)
      end

      it 'returns no content' do
        delete :destroy, params: { id: 1 }
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when destroy raises' do
      before do
        allow(response_double).to receive(:destroy).and_raise(StandardError.new('boom'))
      end

      it 'returns unprocessable_entity with error message' do
        delete :destroy, params: { id: 1 }
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to include('boom')
      end
    end
  end

  describe 'PATCH #unsubmit' do
    let(:response_double) { double('Response') }

    before do
      allow(controller).to receive(:set_response) { controller.instance_variable_set(:@response, response_double) }
      allow(controller).to receive(:has_role?).and_return(true)
    end

    context 'when response not found' do
      before do
        allow(controller).to receive(:set_response) { controller.instance_variable_set(:@response, nil) }
      end

      it 'returns 404' do
        patch :unsubmit, params: { id: 1 }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when response is submitted' do
      before do
        allow(response_double).to receive(:is_submitted?).and_return(true)
        allow(response_double).to receive(:update).with(is_submitted: false).and_return(true)
      end

      it 'reopens the response and returns ok' do
        patch :unsubmit, params: { id: 1 }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body['message']).to eq('Response reopened for revision')
      end
    end

    context 'when response already unsubmitted' do
      before do
        allow(response_double).to receive(:is_submitted?).and_return(false)
      end

      it 'returns unprocessable_entity' do
        patch :unsubmit, params: { id: 1 }
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to eq('Response already unsubmitted')
      end
    end
  end
end
