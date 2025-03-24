require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'
#rspec ./spec/requests/api/v1/responses_controller_spec.rb

RSpec.describe ResponsesController, type: :controller do
  let(:response_map) { double('ResponseMap', id: 1, reviewee_id: 1, type: 'ReviewResponseMap') }
  let(:answer) { create(:answer) }
  let(:response) { Response.new(map_id: 1, response_map: :response_map, scores: [:answer]) }

  describe 'PUT #update' do
    context 'when response exists' do
      it 'returns status success and updates the response' do
        @response = response
        allow(@response).to receive(:update).and_return(true)

        put :update, params: { id: @response.id, review: { comments: 'Updated comment' } }

        expect(response).to have_http_status(:redirect)
        expect(assigns(:response).additional_comment).to eq('Updated comment')
      end
    end

    context 'when response update fails' do
      it 'does not update the response and renders an error' do
        @response = response
        allow(@response).to receive(:update).and_return(false)

        put :update, params: { id: @response.id, review: { comments: '' } }

        expect(response).to have_http_status(:redirect)
        expect(assigns(:response).additional_comment).to eq('Initial comment')
      end
    end
  end
end
