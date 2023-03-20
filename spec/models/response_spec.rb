require 'rails_helper'

RSpec.describe Response, type: :model do

  let(:response) { Response.new(scores: [answer]) }
  let(:answer) { Answer.new(answer: 1, question_id: 1) }
  let(:question) { ScoredQuestion.new(id: 1, weight: 2) }
  let(:questionnaire) { Questionnaire.new(id: 1, questions: [question], max_question_score: 5) }

  describe '#calculate_total_score' do
    it 'computes the total score of a review' do
      question2 = double('ScoredQuestion', weight: 2)
      allow(Question).to receive(:find).with(1).and_return(question2)
      allow(question2).to receive(:is_a?).with(ScoredQuestion).and_return(true)
      allow(question2).to receive(:answer).and_return(answer)
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
      allow(response).to receive(:questionnaire_by_answer).with(answer).and_return(questionnaire)
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
end
