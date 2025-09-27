# frozen_string_literal: true

RSpec.describe CourseSurveyResponseMap, type: :model do
    describe '#questionnaire' do
      it 'returns the questionnaire associated with the reviewed_object_id' do
        survey_deployment = instance_double('SurveyDeployment', questionnaire_id: 1)
        questionnaire = instance_double('Questionnaire')

        allow(Questionnaire).to receive(:find_by).with(id: 1).and_return(questionnaire)

        course_survey_response_map = CourseSurveyResponseMap.new
        allow(course_survey_response_map).to receive(:survey_deployment).and_return(survey_deployment)

        expect(course_survey_response_map.questionnaire).to eq(questionnaire)
      end
    end
  
    describe '#survey_parent' do
      it 'returns the associated assignment' do
        course = double('Course')
        course_survey_response_map = CourseSurveyResponseMap.new
        allow(course_survey_response_map).to receive(:course).and_return(course)
        expect(course_survey_response_map.survey_parent).to eq(course)
      end
    end

    describe '#get_title' do
      it 'returns the correct title constant' do
        course_survey_response_map = CourseSurveyResponseMap.new
        expect(course_survey_response_map.get_title).to eq(ResponseMapSubclassTitles::COURSE_SURVEY_RESPONSE_MAP_TITLE)
      end
    end
  end