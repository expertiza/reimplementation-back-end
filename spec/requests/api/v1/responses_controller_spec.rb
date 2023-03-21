require "rails_helper"

RSpec.describe 'ResponsesController' do
  let(:review_response) {FactoryBot.build(:response, id: 1, map_id:1)}
  let(:team_response) {FactoryBot.build(:response, id: 2, map_id: 2)}
  describe '#delete' do
    it 'deletes current response and redirects to response#redirect page' do
      allow(review_response).to receive(:delete).and_return(review_response)
      request_params = { id: 1 }
      post :delete, params: request_params
      expect(response).to redirect_to('api/v1/response/redirect?id=1&msg=The+response+was+deleted.')
    end

    it 'Redirects away if another user has a lock on the resource' do
      allow(team_response).to receive(:delete).and_return(team_response)
      allow(Lock).to receive(:get_lock).and_return(nil)
      request_params = { id: 2 }
      post :delete, params: request_params
      expect(response).not_to redirect_to('api/v1/response/redirect?id=2&msg=The+response+was+deleted.')
    end
  end
  end