# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResponseMap, type: :model do
  describe '#review_status' do
    let(:map) { create(:review_response_map) }

    it 'returns :not_started when no responses have been created' do
      expect(map.review_status).to eq(:not_started)
    end

    it 'returns :in_progress when a draft (unsubmitted) response exists' do
      Response.create!(response_map: map, round: 1, version_num: 1, is_submitted: false)
      expect(map.review_status).to eq(:in_progress)
    end

    it 'returns :submitted when at least one submitted response exists' do
      Response.create!(response_map: map, round: 1, version_num: 1, is_submitted: true)
      expect(map.review_status).to eq(:submitted)
    end

    it 'returns :submitted even when a later draft also exists' do
      Response.create!(response_map: map, round: 1, version_num: 1, is_submitted: true)
      Response.create!(response_map: map, round: 1, version_num: 2, is_submitted: false)
      expect(map.review_status).to eq(:submitted)
    end
  end
end
