# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Response, type: :model do
  describe '#rubric_label' do
    subject(:label) { response.rubric_label }

    let(:response) { described_class.new }

    context 'when no response_map is set' do
      before { response.response_map = nil }

      it { is_expected.to eq('Response') }
    end

    context 'when the map exposes a title constant' do
      before { response.response_map = TeammateReviewResponseMap.new }

      it { is_expected.to eq(ResponseMapSubclassTitles::TEAMMATE_REVIEW_RESPONSE_MAP_TITLE) }
    end

    context 'when the map provides no title information' do
      before do
        stub_const('MysteryResponseMap', Class.new(ResponseMap))
        response.response_map = MysteryResponseMap.new
      end

      it { is_expected.to eq('Unknown Type') }
    end
  end
end
