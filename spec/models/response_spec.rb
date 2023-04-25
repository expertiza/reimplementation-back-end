require 'rails_helper'

describe Response do

  let(:user) { User.new(id: 1, role_id: 1, name: 'no name', fullname: 'no one') }
  let(:team) {Team.new}
  let(:participant) { build(:participant, id: 1, parent_id: 1, user: user) }
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  let(:question) { ScoredQuestion.new(id: 1, weight: 2) }
  let(:questionnaire) { Questionnaire.new(id: 1, questions: [question], max_question_score: 5) }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  let(:response) { Response.new(map_id: 1, response_map: review_response_map, scores: [answer]) }



  describe '#significant_difference?' do

    context 'when count is 0' do
      it 'returns false' do
        allow(ReviewResponseMap).to receive(:assessments_for).with(team).and_return([response])
        expect(response.significant_difference?).to be false
      end
    end

    context 'when count is not 0' do
      context 'when the difference between average score on same artifact from others and current score is bigger than allowed percentage' do
        it 'returns true' do
          response2 = double('Response', id: 2, aggregate_questionnaire_score: 80, maximum_score: 100)

          allow(ReviewResponseMap).to receive(:assessments_for).with(team).and_return([response2, response2])
          allow(response).to receive(:aggregate_questionnaire_score).and_return(93)
          allow(response).to receive(:maximum_score).and_return(100)
          allow(response).to receive(:questionnaire_by_answer).with(answer).and_return(questionnaire)
          allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 1, questionnaire_id: 1)
                                                             .and_return(double('AssignmentQuestionnaire', notification_limit: 5.0))
          expect(response.significant_difference?).to be true
        end
      end
    end
  end

  describe '#calculate_total_score' do
    it 'computes the total score of a review' do
      question2 = double('ScoredQuestion', weight: 2)
      arr_question2 = [question2]
      allow(Question).to receive(:find_with_order).with([1]).and_return(arr_question2)
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
      arr_question2 = [question2]
      allow(Question).to receive(:find_with_order).with([1]).and_return(arr_question2)
      allow(question2).to receive(:is_a?).with(ScoredQuestion).and_return(true)
      allow(response).to receive(:questionnaire_by_answer).with(answer).and_return(questionnaire)
      allow(questionnaire).to receive(:max_question_score).and_return(5)
      expect(response.maximum_score).to eq(10)
    end

    it 'returns the maximum possible score for current response without score' do
      response.scores = []
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

      expect(response.volume_of_review_comments(1, 1)).to eq([1, 2, 2, 0])
    end
  end
end
