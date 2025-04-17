require 'rails_helper'

RSpec.describe ReviewResponseMap, type: :model do
  describe '.review_allowed?' do
    let(:assignment) { create(:assignment, num_reviews_allowed: 3) }
    let(:reviewer) { create(:user) }
    let(:team) { create(:assignment_team, assignment: assignment) }

    context 'when reviewer has not reached review limit' do
      before do
        # Create 2 reviews for the reviewer (below the limit of 3)
        2.times do
          create(:review_response_map,
                 reviewer_id: reviewer.id,
                 reviewed_object_id: assignment.id,
                 reviewee_id: team.id)
        end
      end

      it 'returns success with allowed true' do
        result = ReviewResponseMap.review_allowed?(assignment.id, reviewer.id)
        expect(result.success).to be true
        expect(result.allowed).to be true
      end
    end

    context 'when reviewer has reached review limit' do
      before do
        # Create 3 reviews for the reviewer (at the limit)
        3.times do
          create(:review_response_map,
                 reviewer_id: reviewer.id,
                 reviewed_object_id: assignment.id,
                 reviewee_id: team.id)
        end
      end

      it 'returns success with allowed false' do
        result = ReviewResponseMap.review_allowed?(assignment.id, reviewer.id)
        expect(result.success).to be true
        expect(result.allowed).to be false
      end
    end

    context 'when parameters are missing' do
      it 'returns error for missing assignment_id' do
        result = ReviewResponseMap.review_allowed?(nil, reviewer.id)
        expect(result.success).to be false
        expect(result.error).to eq('Assignment ID and Reviewer ID are required')
      end

      it 'returns error for missing reviewer_id' do
        result = ReviewResponseMap.review_allowed?(assignment.id, nil)
        expect(result.success).to be false
        expect(result.error).to eq('Assignment ID and Reviewer ID are required')
      end
    end

    context 'when resources are not found' do
      it 'returns error for non-existent assignment' do
        result = ReviewResponseMap.review_allowed?(99999, reviewer.id)
        expect(result.success).to be false
        expect(result.error).to eq('Assignment or Reviewer not found')
      end

      it 'returns error for non-existent reviewer' do
        result = ReviewResponseMap.review_allowed?(assignment.id, 99999)
        expect(result.success).to be false
        expect(result.error).to eq('Assignment or Reviewer not found')
      end
    end

    context 'when an error occurs' do
      before do
        allow(ReviewResponseMap).to receive(:where).and_raise(StandardError.new('Database error'))
      end

      it 'returns failure with error message' do
        result = ReviewResponseMap.review_allowed?(assignment.id, reviewer.id)
        expect(result.success).to be false
        expect(result.error).to eq('Database error')
      end
    end
  end
end 