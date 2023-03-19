require 'rails_helper'

RSpec.describe Response, type: :model do

  let(:response) { Response.new(scores: [answer]) }
  let(:answer) { Answer.new(answer: 1, question_id: 1) }

  describe '#calculate_total_score' do
    it 'computes the total score of a review' do
      question2 = double('ScoredQuestion', weight: 2)
      allow(Question).to receive(:find).with(1).and_return(question2)
      allow(question2).to receive(:is_a?).with(ScoredQuestion).and_return(true)
      allow(question2).to receive(:answer).and_return(answer)
      expect(response.calculate_total_score).to eq(2)
    end
  end

end
