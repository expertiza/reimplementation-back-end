require 'rails_helper'

RSpec.describe ResponsesHelper, type: :helper do
  let(:response) { double('Response', id: 1, map_id: 1) }
  let(:contributor) { double('Contributor', id: 1) }
  let(:assignment) { double('Assignment', id: 1) }
  let(:participant) { double('Participant', id: 1) }
  let(:review_questions) { [double('Question', id: 1), double('Question', id: 2)] }
  let(:response_map) { double('ResponseMap', id: 1, reviewee_id: 1, type: 'ReviewResponseMap') }
  let(:map) { double('ResponseMap') }
  let(:review_response_map) { double('ReviewResponseMap', type: 'ReviewResponseMap', get_title: double('testMap'), 
    survey?: nil, reviewer: double('Reviewer'), contributor: contributor, assignment: :assignment, id: 0) }
  let(:self_review_response_map) { double('SelfReviewResponseMap', type: 'SelfReviewResponseMap') }
  let(:metareview_response_map) { double('MetareviewResponseMap', type: 'MetareviewResponseMap') }
  let(:feedback_response_map) { double('FeedbackResponseMap', type: 'FeedbackResponseMap') }

  before do
    helper.instance_variable_set(:@response, response)
    helper.instance_variable_set(:@assignment, assignment)
    helper.instance_variable_set(:@participant, participant)
    helper.instance_variable_set(:@review_questions, review_questions)
    helper.instance_variable_set(@reviewer, participant)
    helper.instance_variable_set(@review, response)
  end

  describe '#questionnaire_from_response_map' do
    context 'when map type is ReviewResponseMap' do
      it 'calls get_questionnaire_by_contributor' do
        expect(helper).to receive(:get_questionnaire_by_contributor).with(review_response_map, contributor, assignment)
        helper.questionnaire_from_response_map(review_response_map, contributor, assignment)
      end
    end

    context 'when map type is SelfReviewResponseMap' do
      it 'calls get_questionnaire_by_contributor' do
        expect(helper).to receive(:get_questionnaire_by_contributor).with(self_review_response_map, contributor, assignment)
        helper.questionnaire_from_response_map(self_review_response_map, contributor, assignment)
      end
    end

    context 'when map type is not ReviewResponseMap or SelfReviewResponseMap' do
      it 'calls get_questionnaire_by_duty' do
        expect(helper).to receive(:get_questionnaire_by_duty).with(metareview_response_map, assignment)
        helper.questionnaire_from_response_map(metareview_response_map, contributor, assignment)
      end
    end
  end

  describe '#get_questionnaire_by_contributor' do
    it 'returns the correct questionnaire' do
      reviewees_topic = double(1)
      signedUpTeam = double('SignedUpTeam')
      allow(SignedUpTeam).to receive(:find_by).with(team_id: contributor.id).and_return(signedUpTeam)
      allow(signedUpTeam).to receive(:sign_up_topic_id).and_return(reviewees_topic)
      allow(DueDate).to receive(:next_due_date).with(reviewees_topic).and_return(double('DueDate', round: 2))
      allow(map).to receive(:questionnaire).with(2, reviewees_topic).and_return('Questionnaire')

      expect(helper.get_questionnaire_by_contributor(map, contributor, assignment)).to eq('Questionnaire')
    end
  end

  describe '#get_questionnaire_by_duty' do
    context 'when assignment is duty-based' do
      it 'returns the questionnaire by duty' do
        allow(assignment).to receive(:duty_based_assignment?).and_return(true)
        allow(map).to receive(:reviewee).and_return(double('Reviewee', duty_id: 1))
        allow(map).to receive(:questionnaire_by_duty).with(1).and_return('Duty Questionnaire')

        expect(helper.get_questionnaire_by_duty(map, assignment)).to eq('Duty Questionnaire')
      end
    end

    context 'when assignment is not duty-based' do
      it 'returns the generic questionnaire' do
        allow(assignment).to receive(:duty_based_assignment?).and_return(false)
        allow(map).to receive(:questionnaire).and_return('Generic Questionnaire')

        expect(helper.get_questionnaire_by_duty(map, assignment)).to eq('Generic Questionnaire')
      end
    end
  end

  describe '#init_answers' do
    it 'initializes answers for each question if not already present' do
      questions = [double('Question', id: 1), double('Question', id: 2)]
      allow(Answer).to receive(:where).with(response_id: response.id, question_id: 1).and_return([])
      allow(Answer).to receive(:where).with(response_id: response.id, question_id: 2).and_return([])
      expect(Answer).to receive(:create).with(response_id: response.id, question_id: 1, answer: nil, comments: '')
      expect(Answer).to receive(:create).with(response_id: response.id, question_id: 2, answer: nil, comments: '')

      helper.init_answers(response, questions)
    end

    it 'does not create answers if they already exist' do
      questions = [double('Question', id: 1), double('Question', id: 2)]
      allow(Answer).to receive(:where).with(response_id: response.id, question_id: 1).and_return([double('Answer')])
      allow(Answer).to receive(:where).with(response_id: response.id, question_id: 2).and_return([double('Answer')])
      expect(Answer).not_to receive(:create)

      helper.init_answers(response, questions)
    end
  end

  describe '#total_cake_score' do
    it 'returns the total cake score for the reviewee' do
      
      allow(ResponseMap).to receive(:select).with(:reviewee_id, :type).and_return(ResponseMap)
      allow(ResponseMap).to receive(:where).with(id: response.map_id.to_s).and_return([response_map])
      expect(Cake).to receive(:get_total_score_for_questions).with(
        response_map.type,
        review_questions,
        participant.id,
        assignment.id,
        response_map.reviewee_id
      ).and_return(100)

      expect(helper.total_cake_score).to eq(100)
    end
  end

  describe '#find_or_create_feedback' do
    it 'returns the existing FeedbackResponseMap' do
      allow(FeedbackResponseMap).to receive(:where).with(reviewed_object_id: response.id, reviewer_id: participant.id).and_return([feedback_response_map])
      map = find_or_create_feedback
      expect(map).to eq(feedback_response_map)
    end
  end
end

#rspec ./spec/helpers/response_helper_spec.rb
