RSpec.describe TeammateReviewResponseMap, type: :model do
  describe '#questionnaire' do
    it 'returns associated questionnaire' do
      questionnaire = double('Questionnaire')
      assignment = double('Assignment')
      teammate_review_response_map = TeammateReviewResponseMap.new
      allow(teammate_review_response_map).to receive(:assignment).and_return(assignment)
      allow(assignment).to receive_message_chain(:questionnaires, :find_by).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)

      expect(teammate_review_response_map.questionnaire).to eq(questionnaire)
    end
  end

  describe '#questionnaire_by_duty' do
    it 'returns questionnaire by duty_id if exists' do
      questionnaire = double('Questionnaire')
      assignment = double('Assignment')
      teammate_review_response_map = TeammateReviewResponseMap.new
      allow(teammate_review_response_map).to receive(:assignment).and_return(assignment)
      allow(assignment).to receive_message_chain(:questionnaires, :find_by).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)
      allow(AssignmentQuestionnaire).to receive(:find).with(assignment_id: 1, duty_id: 1).and_return(assignment_questionnaire)
      expect(teammate_review_response_map.questionnaire_by_duty(duty_id)).to eq(assignment_questionnaire)
    end

    it 'returns questionnaire method if questionnaire is not found' do
      questionnaire = double('Questionnaire')
      assignment = double('Assignment')
      teammate_review_response_map = TeammateReviewResponseMap.new
      allow(teammate_review_response_map).to receive(:assignment).and_return(assignment)
      allow(assignment).to receive_message_chain(:questionnaires, :find_by).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)
      allow(AssignmentQuestionnaire).to receive(:find).with(assignment_id: 1, duty_id: 1).and_return(nil)
      allow(AssignmentQuestionnaire).to receive(:find_by).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)
      expect(teammate_review_response_map.questionnaire_by_duty(duty_id)).to eq(questionnaire)
    end
  end
end