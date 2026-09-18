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
  let(:assignment_questionnaire) { AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire, used_in_round: 1, notification_threshold: 5.0)}
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team, reviewer: participant2) }
  let(:response_map) { ResponseMap.new(assignment: assignment, reviewee: participant, reviewer: participant2) }
  let(:response) { Response.new(response_map_id: review_response_map.id, response_map: review_response_map, round:1, scores: [answer]) }

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
                                                             .and_return(double('AssignmentQuestionnaire', notification_threshold: 5.0))
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
      allow(response.reviewer_assignment)
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

  describe '#reviewer_assignment' do
    it 'returns assignment for ResponseMap' do
      expect(response_map.reviewer_assignment).to eq(assignment)
    end

    it 'returns assignment for ReviewResponseMap' do
      expect(review_response_map.reviewer_assignment).to eq(assignment)
    end
  end

  describe '#response_assignment (compatibility alias)' do
    it 'delegates to reviewer_assignment for ResponseMap' do
      expect(response_map.response_assignment).to eq(response_map.reviewer_assignment)
    end
  end

  # -------------------------------------------------------------------------
  # Response#questionnaire
  # -------------------------------------------------------------------------
  # The original implementation was a one-liner:
  #   reviewer_assignment.assignment_questionnaires.find_by(used_in_round: self.round).questionnaire
  # For single-round assignments, AssignmentQuestionnaire is stored with used_in_round: nil
  # but Response#round is 1, so find_by returns nil and calling .questionnaire on nil raised
  # NoMethodError. The fix falls back to .first when the round-specific lookup fails.
  describe '#questionnaire' do
    let(:questionnaire_obj) { instance_double(Questionnaire) }

    context 'varying-round assignment (used_in_round matches response.round)' do
      it 'returns the questionnaire for the matching round' do
        aq = instance_double(AssignmentQuestionnaire, questionnaire: questionnaire_obj)
        aq_relation = double('aq_relation')
        allow(aq_relation).to receive(:find_by).with(used_in_round: 1).and_return(aq)
        allow(aq_relation).to receive(:first).and_return(aq)

        allow(response).to receive(:round).and_return(1)
        assignment_double = double('assignment', assignment_questionnaires: aq_relation)
        allow(response).to receive(:reviewer_assignment).and_return(assignment_double)

        expect(response.questionnaire).to eq(questionnaire_obj)
      end
    end

    context 'single-round assignment (used_in_round is nil but response.round is 1)' do
      it 'falls back to the nil-round AssignmentQuestionnaire and returns its questionnaire' do
        aq = instance_double(AssignmentQuestionnaire, questionnaire: questionnaire_obj)
        aq_relation = double('aq_relation')
        # Primary lookup: no AQ stored with used_in_round: 1 (single-round uses nil)
        allow(aq_relation).to receive(:find_by).with(used_in_round: 1).and_return(nil)
        # Deterministic fallback: find_by(used_in_round: nil) targets single-round AQs specifically
        allow(aq_relation).to receive(:find_by).with(used_in_round: nil).and_return(aq)

        allow(response).to receive(:round).and_return(1)
        assignment_double = double('assignment', assignment_questionnaires: aq_relation)
        allow(response).to receive(:reviewer_assignment).and_return(assignment_double)

        expect(response.questionnaire).to eq(questionnaire_obj)
      end

      it 'does not raise NoMethodError when find_by returns nil' do
        aq = instance_double(AssignmentQuestionnaire, questionnaire: questionnaire_obj)
        aq_relation = double('aq_relation')
        allow(aq_relation).to receive(:find_by).with(used_in_round: 1).and_return(nil)
        allow(aq_relation).to receive(:find_by).with(used_in_round: nil).and_return(aq)

        allow(response).to receive(:round).and_return(1)
        assignment_double = double('assignment', assignment_questionnaires: aq_relation)
        allow(response).to receive(:reviewer_assignment).and_return(assignment_double)

        expect { response.questionnaire }.not_to raise_error
      end
    end

    context 'when no AssignmentQuestionnaire exists at all' do
      it 'returns nil safely via the safe-navigator (&.)' do
        aq_relation = double('aq_relation')
        allow(aq_relation).to receive(:find_by).with(used_in_round: 1).and_return(nil)
        # Both lookups return nil — safe-navigator on aq&.questionnaire must not raise
        allow(aq_relation).to receive(:find_by).with(used_in_round: nil).and_return(nil)

        allow(response).to receive(:round).and_return(1)
        assignment_double = double('assignment', assignment_questionnaires: aq_relation)
        allow(response).to receive(:reviewer_assignment).and_return(assignment_double)

        expect { response.questionnaire }.not_to raise_error
        expect(response.questionnaire).to be_nil
      end
    end
  end
end
