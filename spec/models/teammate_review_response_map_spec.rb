RSpec.describe TeammateReviewResponseMap, type: :model do
  describe '#questionnaire' do
    it 'returns associated questionnaire' do
      questionnaire = Questionnaire.new
      teammate_review_response_map = TeammateReviewResponseMap.new
      allow(AssignmentQuestionnaire).to receive(:find_by).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)
      expect(teammate_review_response_map.questionnaire).to eq(questionnaire)
    end
  end

  describe '#questionnaire_by_duty' do
    it 'returns questionnaire by duty_id if exists' do
      assignment_questionnaire = AssignmentQuestionnaire.new
      teammate_review_response_map = TeammateReviewResponseMap.new
      duty_id = 1
      allow(AssignmentQuestionnaire).to receive(:find).with(duty_id: duty_id).and_return(assignment_questionnaire)
      expect(teammate_review_response_map.questionnaire_by_duty(duty_id)).to eq(assignment_questionnaire)
    end

    it 'returns questionnaire method if questionnaire is not found' do
      teammate_review_response_map = TeammateReviewResponseMap.new
      questionnaire = Questionnaire.new
      duty_id = 1
      allow(AssignmentQuestionnaire).to receive(:find).with(duty_id: duty_id).and_return(nil)
      allow(AssignmentQuestionnaire).to receive(:find_by).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)
      expect(teammate_review_response_map.questionnaire_by_duty(duty_id)).to eq(questionnaire)
    end
  end
end