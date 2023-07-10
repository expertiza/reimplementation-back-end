require 'rails_helper'

RSpec.describe Assignment, type: :model do

  let(:team) {Team.new}
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  let(:answer2) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }

  describe '.get_all_review_comments' do
    it 'returns concatenated review comments and # of reviews in each round' do
      allow(Assignment).to receive(:find).with(1).and_return(assignment)
      allow(assignment).to receive(:num_review_rounds).and_return(2)
      allow(Question).to receive(:get_questions_with_comments_for_assignment).with(1).and_return([1, 2])
      allow(ReviewResponseMap).to receive_message_chain(:where, :find_each).with(reviewed_object_id: 1, reviewer_id: 1)
                                                                           .with(no_args).and_yield(review_response_map)
      response1 = double('Response', round: 1, additional_comment: '')
      response2 = double('Response', round: 2, additional_comment: 'LGTM')
      allow(review_response_map).to receive(:response).and_return([response1, response2])
      allow(response1).to receive(:scores).and_return([answer])
      allow(response2).to receive(:scores).and_return([answer2])
      expect(assignment.get_all_review_comments(1)).to eq([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
    end
  end

  # Get a collection of all comments across all rounds of a review as well as a count of the total number of comments. Returns the above
  # information both for totals and in a list per-round.
  describe '.volume_of_review_comments' do
    it 'returns volumes of review comments in each round' do
      allow(assignment).to receive(:get_all_review_comments).with(1)
                                                                  .and_return([[nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
      expect(assignment.volume_of_review_comments(1)).to eq([1, 2, 2, 0])
    end
  end
end
