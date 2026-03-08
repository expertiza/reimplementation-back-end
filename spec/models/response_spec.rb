# frozen_string_literal: true

require 'rails_helper'

describe Response do

  let(:user) { create(:user, :student) }
  let(:user2) { create(:user, :student) }
  let(:assignment) { create(:assignment, name: 'Test Assignment') }
  let(:team) {create(:team, :with_assignment, name: 'Test Team')}
  let(:participant) { AssignmentParticipant.create!(assignment: assignment, user: user, handle: user.name) }
  let(:participant2) { AssignmentParticipant.create!(assignment: assignment, user: user2, handle: user2.name) }
  let(:item) { ScoredItem.new(weight: 2) }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', item:item) }
  let(:questionnaire) { Questionnaire.new(items: [item], min_question_score: 0, max_question_score: 5) }
  let(:assignment_questionnaire) { AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire, used_in_round: 1, notification_limit: 5.0)}
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team, reviewer: participant2) }
  let(:response_map) { ResponseMap.new(assignment: assignment, reviewee: participant, reviewer: participant2) }
  let(:response) { Response.new(map_id: review_response_map.id, response_map: review_response_map, round:1, scores: [answer]) }

  # Compare the current response score with other scores on the same artifact, and test if the difference is significant enough to notify
  # instructor.
  describe '#reportable_difference?' do
    context 'when count is 0' do
      it 'returns false' do
        allow(ReviewResponseMap).to receive(:assessments_for).with(team).and_return([response])
        expect(response.reportable_difference?).to be false
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
          allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: assignment.id, questionnaire_id: questionnaire.id)
                                                             .and_return(double('AssignmentQuestionnaire', notification_limit: 5.0))
          expect(response.reportable_difference?).to be true
        end
      end
    end
  end

  # Calculate the total score of a review
  describe '#aggregate_questionnaire_score' do
    it 'computes the total score of a review' do
      expect(response.aggregate_questionnaire_score).to eq(2)
    end
  end

  # Calculate Average score with maximum score as zero and non-zero
  describe '#average_score' do
    context 'when maximum_score returns 0' do
      it 'returns N/A' do
        allow(response).to receive(:maximum_score).and_return(0)
        expect(response.average_score).to eq(0)
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

  # Returns the maximum possible score for this response - only count the scorable questions, only when the answer is not nil (we accept nil as
  # answer for scorable questions, and they will not be counted towards the total score)
  describe '#maximum_score' do
    before do
      allow(response.response_assignment)
        .to receive_message_chain(:assignment_questionnaires, :find_by)
        .with(used_in_round: 1)
        .and_return(assignment_questionnaire)
    end
    context 'when answers are present and scorable' do
      it 'returns weight * max_question_score' do
        # item.weight = 2, max_question_score = 5 → 10        
        expect(response.maximum_score).to eq(10)
      end
    end

    context 'when answer is nil' do
      before { answer.answer = nil }

      it 'does not count that answer' do        
        expect(response.maximum_score).to eq(0)
      end
    end

    context 'when there are no scores' do
      before { response.scores = [] }

      it 'returns 0' do
        # allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: assignment.id, questionnaire_id: questionnaire.id)
        #                                                      .and_return(double('AssignmentQuestionnaire', notification_limit: 5.0))
        expect(response.maximum_score).to eq(0)
      end
    end
  end

  describe '#response_assignment' do
    it 'returns assignment for ResponseMap' do
      expect(response_map.response_assignment).to eq(assignment)
    end

    it 'returns assignment for ReviewResponseMap' do
      expect(review_response_map.response_assignment).to eq(assignment)
    end
  end
end
