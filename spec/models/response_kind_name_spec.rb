# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Response, type: :model do
  describe '#kind_name' do
    let(:response) { described_class.new }

    context 'when response_map is nil' do
      it 'returns "Response" by default' do
        response.response_map = nil
        expect(response.kind_name).to eq('Response')
      end
    end

    context 'when the map defines get_title' do
      it 'returns the value of get_title if not present in the response map' do
        map = ReviewResponseMap.new
        allow(map).to receive(:get_title).and_return('Review')
        response.response_map = map
        expect(response.kind_name).to eq('Review')

        map2 = CourseSurveyResponseMap.new
        allow(map).to receive(:get_title).and_return('Course Survey')
        response.response_map = map2
        expect(response.kind_name).to eq('Course Survey')
      end
    end

    context 'when the map does not define get_title' do
      it 'returns the mapped label if present in KIND_LABELS' do
        map = TeammateReviewResponseMap.new
        response.response_map = map
        expect(response.kind_name).to eq('Teammate Review')
      end
    end
  end
end
