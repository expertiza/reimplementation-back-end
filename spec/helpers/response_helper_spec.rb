require 'rails_helper'

RSpec.describe ResponseHelper, type: :helper do
  let(:map) { create(:response_map) }
  let(:current_round) { 1 }
  let(:questionnaire) { create(:questionnaire) }
  let(:response) { create(:response, map: map, round: current_round) }

  before do
    allow(map).to receive(:get_title).and_return('Test Title')
    allow(map).to receive(:survey?).and_return(false)
    allow(map).to receive(:assignment).and_return(create(:assignment))
    allow(map).to receive(:reviewer).and_return(create(:user))
    allow(map).to receive(:contributor).and_return(create(:user))
    allow(helper).to receive(:questionnaire_from_response_map).and_return(questionnaire)
    allow(helper).to receive(:sort_questions).and_return([])
    allow(questionnaire).to receive(:min_question_score).and_return(1)
    allow(questionnaire).to receive(:max_question_score).and_return(5)
    allow(helper).to receive(:set_dropdown_or_scale)
  end

  describe '.prepare_response_content' do
    context 'when action is new' do
      it 'returns correct response data for new action' do
        action_params = { action: 'new', id: 0, feedback: 'some feedback', return: 'some_return' }
        response_data = helper.prepare_response_content(map, current_round, action_params, new_response: true)

        expect(response_data[:header]).to eq('New')
        expect(response_data[:next_action]).to eq('create')
        expect(response_data[:map]).to eq(map)
        expect(response_data[:feedback]).to eq('some feedback')
      end
    end

    context 'when action is edit' do
      it 'returns correct response data for edit action' do
        action_params = { action: 'edit', id: 0, return: 'some_return' }
        allow(Response).to receive(:find).with(response.id).and_return(response)

        response_data = helper.prepare_response_content(map, current_round, action_params)

        expect(response_data[:header]).to eq('Edit')
        expect(response_data[:next_action]).to eq('update')
        expect(response_data[:response]).to eq(response)
      end
    end

    context 'when no action params are given' do
      it 'returns default response data' do
        response_data = helper.prepare_response_content(map, current_round)

        expect(response_data[:header]).to eq('Default Header')
        expect(response_data[:next_action]).to eq('create')
      end
    end
  end
end

#rspec ./spec/helpers/response_helper_spec.rb
