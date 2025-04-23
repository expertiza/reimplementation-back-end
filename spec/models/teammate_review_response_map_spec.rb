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
    it 'returns questionnaire specific to a duty' do
      questionnaire = double('Questionnaire')
      assignment = double('Assignment', assignment_id: 1)
      teammate_review_response_map = TeammateReviewResponseMap.new
      allow(teammate_review_response_map).to receive(:assignment).and_return(assignment)
      allow(assignment).to receive_message_chain(:questionnaires, :find).with(assignment_id: 1, duty_id: 1).and_return([questionnaire])
      expect(teammate_review_response_map.questionnaire_by_duty(1)).to eq(questionnaire)
    end
    it 'returns default questionnaire when no questionnaire is found for duty' do
      questionnaire = double('Questionnaire')
      assignment = double('Assignment', assignment_id: 1)
      teammate_review_response_map = TeammateReviewResponseMap.new
      allow(teammate_review_response_map).to receive(:assignment).and_return(assignment)
      allow(assignment).to receive(:questionnaires).and_return(questionnaire)
      allow(assignment).to receive_message_chain(:questionnaires, :find).with(assignment_id: 1, duty_id: 1).and_return([])
      allow(assignment).to receive_message_chain(:questionnaires, :find_by).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)
      expect(teammate_review_response_map.questionnaire_by_duty(1)).to eq(questionnaire)
    end
  end
end