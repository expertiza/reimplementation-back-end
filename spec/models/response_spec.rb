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

  # -------------------------------------------------------------------------
  # E2619: quiz response scoring
  # Quiz maps are identified by reviewer_id == reviewee_id. Items store the
  # student's answer in the `comments` column (not `answer`).
  # -------------------------------------------------------------------------
  describe '#aggregate_questionnaire_score (quiz)' do
    # Build a fake quiz map where reviewer_id == reviewee_id
    let(:quiz_map) do
      map = double('ResponseMap')
      allow(map).to receive(:reviewer_id).and_return(5)
      allow(map).to receive(:reviewee_id).and_return(5)
      allow(map).to receive(:response_assignment).and_return(assignment)
      allow(map).to receive(:reviewee).and_return(participant)
      allow(map).to receive(:reviewer).and_return(participant)
      map
    end

    def make_quiz_item(question_type:, correct_answer:, weight: 1)
      i = double('Item', question_type: question_type, correct_answer: correct_answer, weight: weight)
      i
    end

    def make_quiz_answer(item:, comments:)
      a = double('Answer', item: item, comments: comments, answer: nil)
      a
    end

    def quiz_response(scores)
      r = Response.new(map_id: nil, round: nil)
      r.instance_variable_set(:@response_map, quiz_map)
      allow(r).to receive(:map).and_return(quiz_map)
      allow(r).to receive(:scores).and_return(scores)
      r
    end

    context 'with spaced question type names (frontend convention)' do
      it 'scores a correct "Text field" answer' do
        item = make_quiz_item(question_type: 'Text field', correct_answer: 'Paris', weight: 2)
        answer = make_quiz_answer(item: item, comments: 'paris') # case-insensitive
        r = quiz_response([answer])
        expect(r.aggregate_questionnaire_score).to eq(2)
      end

      it 'scores an incorrect "Text field" answer as 0' do
        item = make_quiz_item(question_type: 'Text field', correct_answer: 'Paris', weight: 2)
        answer = make_quiz_answer(item: item, comments: 'London')
        r = quiz_response([answer])
        expect(r.aggregate_questionnaire_score).to eq(0)
      end

      it 'scores a correct "Multiple choice" answer' do
        item = make_quiz_item(question_type: 'Multiple choice', correct_answer: 'Option A', weight: 3)
        answer = make_quiz_answer(item: item, comments: 'Option A')
        r = quiz_response([answer])
        expect(r.aggregate_questionnaire_score).to eq(3)
      end

      it 'scores a correct "Multiple choice checkbox" answer' do
        item = make_quiz_item(question_type: 'Multiple choice checkbox', correct_answer: 'Option B', weight: 1)
        answer = make_quiz_answer(item: item, comments: 'Option B')
        r = quiz_response([answer])
        expect(r.aggregate_questionnaire_score).to eq(1)
      end

      it 'accumulates points from multiple correct answers' do
        item1 = make_quiz_item(question_type: 'Text field', correct_answer: 'Yes', weight: 1)
        item2 = make_quiz_item(question_type: 'Multiple choice', correct_answer: 'A', weight: 2)
        a1 = make_quiz_answer(item: item1, comments: 'yes')
        a2 = make_quiz_answer(item: item2, comments: 'A')
        r = quiz_response([a1, a2])
        expect(r.aggregate_questionnaire_score).to eq(3)
      end

      it 'gives 0 when the comments column is blank even if correct_answer is set' do
        item = make_quiz_item(question_type: 'Text field', correct_answer: 'Paris', weight: 2)
        answer = make_quiz_answer(item: item, comments: '')
        r = quiz_response([answer])
        expect(r.aggregate_questionnaire_score).to eq(0)
      end
    end

    context 'with CamelCase question type names (legacy convention)' do
      it 'scores a correct "TextField" answer' do
        item = make_quiz_item(question_type: 'TextField', correct_answer: 'Yes', weight: 1)
        answer = make_quiz_answer(item: item, comments: 'Yes')
        r = quiz_response([answer])
        expect(r.aggregate_questionnaire_score).to eq(1)
      end

      it 'scores a correct "MultipleChoiceRadio" answer' do
        item = make_quiz_item(question_type: 'MultipleChoiceRadio', correct_answer: 'B', weight: 2)
        answer = make_quiz_answer(item: item, comments: 'B')
        r = quiz_response([answer])
        expect(r.aggregate_questionnaire_score).to eq(2)
      end

      it 'scores a correct "MultipleChoiceCheckbox" answer' do
        item = make_quiz_item(question_type: 'MultipleChoiceCheckbox', correct_answer: 'C', weight: 1)
        answer = make_quiz_answer(item: item, comments: 'C')
        r = quiz_response([answer])
        expect(r.aggregate_questionnaire_score).to eq(1)
      end
    end
  end

  describe '#maximum_score (quiz)' do
    let(:quiz_map) do
      map = double('ResponseMap')
      allow(map).to receive(:reviewer_id).and_return(5)
      allow(map).to receive(:reviewee_id).and_return(5)
      allow(map).to receive(:response_assignment).and_return(assignment)
      allow(map).to receive(:reviewee).and_return(participant)
      allow(map).to receive(:reviewer).and_return(participant)
      map
    end

    def make_quiz_item(question_type:, weight: 1)
      double('Item', question_type: question_type, weight: weight)
    end

    def make_quiz_answer(item:, comments: '')
      double('Answer', item: item, comments: comments, answer: nil)
    end

    def quiz_questionnaire_double
      double('Questionnaire', max_question_score: 5)
    end

    def quiz_response_with_questionnaire(scores)
      r = Response.new(map_id: nil, round: nil)
      r.instance_variable_set(:@response_map, quiz_map)
      allow(r).to receive(:map).and_return(quiz_map)
      allow(r).to receive(:questionnaire).and_return(quiz_questionnaire_double)
      allow(r).to receive(:scores).and_return(scores)
      r
    end

    it 'counts comment-scored items even when answer is nil' do
      # weight=2, max_question_score=5 → maximum = 2*5 = 10
      item = make_quiz_item(question_type: 'Text field', weight: 2)
      a = make_quiz_answer(item: item)
      r = quiz_response_with_questionnaire([a])
      expect(r.maximum_score).to eq(10)
    end

    it 'accumulates weights for all quiz items' do
      item1 = make_quiz_item(question_type: 'Multiple choice', weight: 1)
      item2 = make_quiz_item(question_type: 'TextField', weight: 3)
      a1 = make_quiz_answer(item: item1)
      a2 = make_quiz_answer(item: item2)
      r = quiz_response_with_questionnaire([a1, a2])
      # (1+3) * max_question_score(5) = 20
      expect(r.maximum_score).to eq(20)
    end

    it 'returns 0 when there are no quiz items' do
      r = quiz_response_with_questionnaire([])
      expect(r.maximum_score).to eq(0)
    end
  end
end