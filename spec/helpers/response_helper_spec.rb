require 'rails_helper'

RSpec.describe ResponsesHelper, type: :helper do
  let(:contributor) { double('Contributor', id: 1) }
  let(:assignment) { double('Assignment') }
  let(:map) { double('ResponseMap') }
  let(:review_response_map) { double('ReviewResponseMap', type: 'ReviewResponseMap', get_title: double('testMap'), 
    survey?: nil, reviewer: double('Reviewer'), contributor: contributor, assignment: :assignment, id: 0) }
  let(:self_review_response_map) { double('SelfReviewResponseMap', type: 'SelfReviewResponseMap') }
  let(:metareview_response_map) { double('MetareviewResponseMap', type: 'MetareviewResponseMap') }

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
end

#rspec ./spec/helpers/response_helper_spec.rb
