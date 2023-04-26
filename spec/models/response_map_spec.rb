require 'rails_helper'

RSpec.describe ResponseMap, type: :model do
  let(:team) {Team.new}
  let(:participant) { Participant.new(id: 1) }
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }

  describe ".get_all_responses" do
    it "returns all responses by a particular reviewer" do
      response_map = ReviewResponseMap.create!(assignment: assignment, reviewer: participant, reviewee: team)

      response1 = Response.create!(response_map: response_map)
      response2 = Response.create!(response_map: response_map)

      expect(response_map.get_all_responses).to eq([response1, response2])
    end
  end
end
