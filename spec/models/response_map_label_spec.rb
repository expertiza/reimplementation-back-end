# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponseMap, type: :model do
  describe '#response_map_label' do
    subject(:label) { map.response_map_label }

    context 'when the subclass defines a title constant' do
      let(:map) { TeammateReviewResponseMap.new }

      it { is_expected.to eq(ResponseMapSubclassTitles::TEAMMATE_REVIEW_RESPONSE_MAP_TITLE) }
    end

    context 'when no title information is available' do
      let(:map) { ResponseMap.new }

      it { is_expected.to be_nil }
    end
  end
end
