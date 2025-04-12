RSpec.describe SurveyResponseMap, type: :model do
    describe '#survey?' do
        it 'returns true' do
            survey_response_map = SurveyResponseMap.new
            expect(survey_response_map.survey?).to be true
        end
    end
end