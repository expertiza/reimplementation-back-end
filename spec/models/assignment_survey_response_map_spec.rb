# frozen_string_literal: true

RSpec.describe AssignmentSurveyResponseMap, type: :model do
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
        assignment = double('Assignment')
        assignment_survey_response_map = AssignmentSurveyResponseMap.new
        allow(assignment_survey_response_map).to receive(:assignment).and_return(assignment)
        expect(assignment_survey_response_map.survey_parent).to eq(assignment)
      end
    end
    
    describe '#get_title' do
      it 'returns the correct title constant' do
        assignment_survey_response_map = AssignmentSurveyResponseMap.new
        expect(assignment_survey_response_map.get_title).to eq(ResponseMapSubclassTitles::ASSIGNMENT_SURVEY_RESPONSE_MAP_TITLE)
      end
    end
  end