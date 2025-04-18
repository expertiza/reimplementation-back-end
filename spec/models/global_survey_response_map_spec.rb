RSpec.describe GlobalSurveyResponseMap, type: :model do
    describe '#questionnaire' do
      it 'returns the questionnaire associated with the reviewed_object_id' do
        questionnaire = instance_double('Questionnaire')
        allow(Questionnaire).to receive(:find_by).with(id: 1).and_return(questionnaire)
        assignment_survey_response_map = AssignmentSurveyResponseMap.new(reviewed_object_id: 1)
        expect(assignment_survey_response_map.questionnaire).to eq(questionnaire)
      end
    end
  
    describe '#survey_parent' do
      it 'returns the associated assignment' do
        questionnaire = double('Questionnaire')
        global_survey_response_map = GlobalSurveyResponseMap.new
        allow(global_survey_response_map).to receive(:questionnaire).and_return(questionnaire)
        expect(global_survey_response_map.survey_parent).to eq(questionnaire)
      end
    end
  end