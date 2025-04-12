RSpec.describe SurveyResponseMap, type: :model do
    describe '#survey?' do
        it 'returns true' do
            survey_response_map = SurveyResponseMap.new
            expect(survey_response_map.survey?).to be true
        end
    end

    describe '#contributor' do
        it 'returns nil' do
        survey_response_map = SurveyResponseMap.new
        expect(survey_response_map.contributor).to be_nil
        end
    end
end