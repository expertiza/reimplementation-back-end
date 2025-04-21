Rspec.describe FeedbackResponseMap, type: :model do 

    describe '#assignment' do
        it 'returns the assignment associated with this FeedbackResponseMap' do
            expect(feedback_response_map.assignment).to eq(assignment)
        end
    end

    describe '#questionnaire' do
        it 'returns an AuthorFeedbackQuestionnaire' do
        expect(feedback_response_map.questionnaire.first.type).to eq('AuthorFeedbackQuestionnaire')
        end
  end