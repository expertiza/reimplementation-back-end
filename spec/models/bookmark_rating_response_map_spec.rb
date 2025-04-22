RSpec.describe BookmarkRatingResponseMap, type: :model do
  describe '#questionnaire' do
    it 'returns the questionnaire associated with the reviewed_object_id' do
      questionnaire = instance_double('Questionnaire')
      allow(Questionnaire).to receive(:where).with(type: 'BookmarkRatingResponseMap').and_return(questionnaire)
      assignment_survey_response_map = AssignmentSurveyResponseMap.new(reviewed_object_id: 1)
      expect(assignment_survey_response_map.questionnaire).to eq(questionnaire)
    end
  end
end