require 'rails_helper'

RSpec.describe Response, type: :model do

  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:response) { Response.new(scores: [answer1]) }
  let(:answer1) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  let(:answer2) { Answer.new(answer: 2, comments: 'Answer text', question_id: 2) }
  let(:question) { ScoredQuestion.new(id: 1, weight: 2) }
  let(:questionnaire) { Questionnaire.new(id: 1, questions: [question], max_question_score: 5) }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment) }

  describe '#calculate_total_score' do
    it 'computes the total score of a review' do
      question2 = double('ScoredQuestion', weight: 2)
      allow(Question).to receive(:find).with(1).and_return(question2)
      allow(question2).to receive(:is_a?).with(ScoredQuestion).and_return(true)
      allow(question2).to receive(:answer1).and_return(answer1)
      expect(response.calculate_total_score).to eq(2)
    end
  end

  describe '#average_score' do
    context 'when maximum_score returns 0' do
      it 'returns N/A' do
        allow(response).to receive(:maximum_score).and_return(0)
        expect(response.average_score).to eq('N/A')
      end
    end

    context 'when maximum_score does not return 0' do
      it 'calculates the maximum score' do
        allow(response).to receive(:calculate_total_score).and_return(4)
        allow(response).to receive(:maximum_score).and_return(5)
        expect(response.average_score).to eq(80)
      end
    end
  end

  describe '#maximum_score' do
    it 'returns the maximum possible score for current response' do
      question2 = double('ScoredQuestion', weight: 2)
      allow(Question).to receive(:find).with(1).and_return(question2)
      allow(question2).to receive(:is_a?).with(ScoredQuestion).and_return(true)
      allow(response).to receive(:questionnaire_by_answer).with(answer1).and_return(questionnaire)
      allow(questionnaire).to receive(:max_question_score).and_return(5)
      expect(response.maximum_score).to eq(10)
    end

    it 'returns the maximum possible score for current response without score' do
      response.scores = []
      question2 = double('ScoredQuestion', weight: 2)
      allow(Question).to receive(:find).with(1).and_return(question2)
      allow(question2).to receive(:is_a?).with(ScoredQuestion).and_return(false)
      allow(response).to receive(:questionnaire_by_answer).with(nil).and_return(questionnaire)
      allow(questionnaire).to receive(:max_question_score).and_return(5)
      expect(response.maximum_score).to eq(0)
    end
  end

  describe '.volume_of_review_comments' do
    it 'returns volumes of review comments in each round' do
      allow(Response).to receive(:get_all_review_comments)
                           .with(1, 1)
                           .and_return([
                                         'Answer textAnswer textLGTM',
                                         2,
                                         [nil, 'Answer text', 'Answer textLGTM', ''],
                                         [nil, 1, 1, 0]
                                       ])
      expect(ReviewCommentMixin.volume_of_review_comments(1, 1)).to eq([1, 2, 2, 0])
    end
  end

  describe '.concatenate_all_review_comments' do
    it 'returns concatenated review comments and # of reviews in each round' do
      allow(Assignment).to receive(:find).with(1).and_return(assignment)
      allow(assignment).to receive(:num_review_rounds).and_return(2)
      allow(Question).to receive(:get_all_questions_with_comments_available).with(1).and_return([1, 2])
      allow(ReviewResponseMap).to receive_message_chain(:where, :find_each).with(reviewed_object_id: 1, reviewer_id: 1)
                                                                           .with(no_args).and_yield(review_response_map)
      response1 = double('Response', round: 1, additional_comment: '')
      response2 = double('Response', round: 2, additional_comment: 'LGTM')
      allow(review_response_map).to receive(:response).and_return([response1, response2])
      allow(response1).to receive(:scores).and_return([answer1])
      allow(response2).to receive(:scores).and_return([answer2])
      expect(Response.get_all_review_comments(1, 1)).to eq(['Answer textAnswer textLGTM', 2, [nil, 'Answer text', 'Answer textLGTM', ''], [nil, 1, 1, 0]])
    end
  end

  describe ".prev_reviews_count" do
    context 'when current response is not in current response array' do
      it 'returns the count of previous reviews' do
        allow(response).to receive(:aggregate_questionnaire_score).and_return(96)
        allow(response).to receive(:maximum_score).and_return(100)
        expect(Response.prev_reviews_count([response], double('Response', id: 6))).to eq(1)
      end
    end
  end

  describe ".prev_reviews_avg_scores" do
    context 'when current response is not in current response array' do
      it 'returns the average score of previous reviews' do
        allow(response).to receive(:aggregate_questionnaire_score).and_return(96)
        allow(response).to receive(:maximum_score).and_return(100)
        expect(Response.prev_reviews_avg_scores([response], double('Response', id: 6))).to eq(0.96)
      end
    end
  end

  describe ".get_latest_response" do
    it "returns the latest response by a particular reviewer" do
      reviewee = Participant.create!
      reviewer = Participant.create!
      response_map = ReviewResponseMap.create!(assignment: assignment, reviewer: reviewer, reviewee: reviewee)

      response1 = Response.create!(response_map: response_map)
      response2 = Response.create!(response_map: response_map)

      expect(Response.get_latest_response(assignment, reviewer, reviewee)).to eq(response2)
    end
  end
end
