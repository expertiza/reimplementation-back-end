# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReviewMappingHandler do
  describe '#calibration_reviews_for' do
    it 'returns only calibration review maps for the handler assignment and reviewer' do
      assignment = create(:assignment)
      other_assignment = create(:assignment)
      reviewer = create(:assignment_participant, assignment: assignment)

      calibration_map = create(:review_response_map, :for_calibration, assignment: assignment, reviewer: reviewer)
      create(:review_response_map, assignment: assignment, reviewer: reviewer)
      create(:review_response_map, :for_calibration, assignment: other_assignment)

      result = described_class.new(assignment).calibration_reviews_for(reviewer)

      expect(result).to contain_exactly(calibration_map)
    end
  end

  describe '#assign_calibration_reviews_round_robin' do
    it 'creates calibration maps against existing calibration reviewees' do
      assignment = create(:assignment)
      reviewers = create_list(:assignment_participant, 2, assignment: assignment)
      calibration_teams = create_list(:assignment_team, 2, assignment: assignment)

      create(:review_response_map, :for_calibration, assignment: assignment, reviewee: calibration_teams.first)
      create(:review_response_map, :for_calibration, assignment: assignment, reviewee: calibration_teams.second)

      described_class.new(assignment).assign_calibration_reviews_round_robin

      reviewers.each do |reviewer|
        maps = ReviewResponseMap.where(
          reviewer: reviewer,
          reviewed_object_id: assignment.id,
          for_calibration: true
        )

        expect(maps.count).to eq(2)
        expect(maps.pluck(:reviewee_id)).to match_array(calibration_teams.map(&:id))
      end
    end
  end
end
