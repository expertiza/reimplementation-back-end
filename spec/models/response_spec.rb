# frozen_string_literal: true

require 'rails_helper'

describe Response do
  let(:user) { User.new(id: 1, role_id: 1, name: 'no name', full_name: 'no one') }
  let(:team) { Team.new }
  let(:participant) { Participant.new(id: 1, user: user) }
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  let(:item) { ScoredItem.new(id: 1, weight: 2) }
  let(:questionnaire) { Questionnaire.new(id: 1, items: [item], max_question_score: 5) }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  let(:response_map) { ResponseMap.new(assignment: assignment, reviewee: participant, reviewer: participant) }
  let(:response) { Response.new(map_id: 1, response_map: review_response_map, scores: [answer]) }

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
          allow(AssignmentQuestionnaire).to receive(:find_by).with(assignment_id: 1, questionnaire_id: 1)
                                                             .and_return(double('AssignmentQuestionnaire',
                                                                                notification_limit: 5.0))
          expect(response.reportable_difference?).to be true
        end
      end
    end
  end

  # Calculate the total score of a review
  describe '#calculate_total_score' do
    it 'computes the total score of a review' do
      # question2 = double('ScoredItem', weight: 2)
      # arr_question2 = [question2]
      # allow(Item).to receive(:find_with_order).with([1]).and_return(arr_question2)
      # allow(question2).to receive(:scorable?).and_return(true)
      # allow(question2).to receive(:answer).and_return(answer)
      # expect(response.calculate_total_score).to eq(2)

      # Our Answer above has question_id: 1
      allow(Item).to receive(:find).with(1).and_return(item)
      allow(item).to receive(:scorable?).and_return(true)

      # answer.answer == 1, item.weight == 2  ->  1 * 2 = 2
      expect(response.calculate_total_score).to eq(2)
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
    it 'returns the maximum possible score for current response' do
      question2 = double('ScoredItem', weight: 2)
      arr_question2 = [question2]
      allow(Item).to receive(:find_with_order).with([1]).and_return(arr_question2)
      allow(question2).to receive(:scorable?).and_return(true)
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

    # Expects to return the participant's assignment for a ResponseMap object
    it 'returns the appropriate assignment for ResponseMap' do
      allow(Participant).to receive(:find).and_return(participant)
      allow(participant).to receive(:assignment).and_return(assignment)

      expect(response_map.response_assignment).to eq(assignment)
    end

    # Expects to return ResponseMap's assignment
    it 'returns the appropriate assignment for ReviewResponseMap' do
      question2 = double('ScoredItem', weight: 2)
      arr_question2 = [question2]
      allow(Item).to receive(:find_with_order).with([1]).and_return(arr_question2)
      allow(question2).to receive(:scorable?).and_return(true)
      allow(questionnaire).to receive(:max_question_score).and_return(5)
      allow(review_response_map).to receive(:assignment).and_return(assignment)

      expect(review_response_map.response_assignment).to eq(assignment)
    end
  end
  # Weighted rubric math
  describe '#calculate_total_score (weighted)' do
    it 'adds weight * answer for scorable items' do
      # Item A: weight=2, answer=3
      item_a = instance_double('ScoredItem', id: 101, weight: 2)
      answer_a = Answer.new(answer: 3, question_id: 101)

      # Item B: weight=1, answer=5
      item_b = instance_double('ScoredItem', id: 102, weight: 1)
      answer_b = Answer.new(answer: 5, question_id: 102)

      resp = Response.new(map_id: 1, response_map: review_response_map, scores: [answer_a, answer_b])

      allow(Item).to receive(:find).with(101).and_return(item_a)
      allow(Item).to receive(:find).with(102).and_return(item_b)
      allow(item_a).to receive(:scorable?).and_return(true)
      allow(item_b).to receive(:scorable?).and_return(true)

      expect(resp.calculate_total_score).to eq(3 * 2 + 5 * 1) # 11
    end
  end
  # Ignore non-scorable and nil answers
  describe '#calculate_total_score (skips non-scorable and nil)' do
    it 'ignores items that are not scorable and answers that are nil' do
      item_c = instance_double('Item', id: 201, weight: 10)
      answer_c = Answer.new(answer: nil, question_id: 201) # nil -> ignored

      item_d = instance_double('Item', id: 202, weight: 5)
      answer_d = Answer.new(answer: 4, question_id: 202)   # but item_d non-scorable

      resp = Response.new(map_id: 1, response_map: review_response_map, scores: [answer_c, answer_d])

      allow(Item).to receive(:find).with(201).and_return(item_c)
      allow(Item).to receive(:find).with(202).and_return(item_d)
      allow(item_c).to receive(:scorable?).and_return(true)   # but answer is nil
      allow(item_d).to receive(:scorable?).and_return(false)  # non-scorable

      expect(resp.calculate_total_score).to eq(0)
    end
  end
end
