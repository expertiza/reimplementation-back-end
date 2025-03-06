require 'rails_helper'

RSpec.describe ResponseService, type: :service do
  let(:map) { create(:response_map) }  
  let(:current_round) { 1 }

  describe '.prepare_response_data' do
    context 'when action is new' do
      it 'returns correct response data for new action' do
        action_params = { action: 'new', id: map.id, feedback: 'some feedback', return: 'some_return' }
        response_data = ResponseService.prepare_response_data(map, current_round, action_params, new_response: true)

        expect(response_data[:header]).to eq('New')
        expect(response_data[:next_action]).to eq('create')
        expect(response_data[:map]).to eq(map)
        expect(response_data[:feedback]).to eq('some feedback')
      end
    end

    context 'when action is edit' do
      it 'returns correct response data for edit action' do
        response = create(:response, map: map)  
        action_params = { action: 'edit', id: response.id, return: 'some_return' }
        response_data = ResponseService.prepare_response_data(map, current_round, action_params)

        expect(response_data[:header]).to eq('Edit')
        expect(response_data[:next_action]).to eq('update')
        expect(response_data[:response]).to eq(response)
      end
    end
  end
end
