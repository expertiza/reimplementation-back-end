RSpec.describe FeedbackResponseMap, type: :model do 
    describe '#assignment' do
      it 'returns the assignment associated with this FeedbackResponseMap' do
        assignment = instance_double('Assignment')
        allow(Assignment).to receive(:find).with(1).and_return(assignment)
        feedback_response_map = FeedbackResponseMap.new(reviewed_object_id: 1) 
        allow(feedback_response_map).to receive(:assignment).and_return(assignment)
        expect(feedback_response_map.assignment).to eq(assignment)
      end
    end
  
    describe '#questionnaire' do
      it 'returns an AuthorFeedbackQuestionnaire' do
        questionnaire = instance_double('Questionnaire')
        allow(questionnaire).to receive(:questionnaire_type).and_return('AuthorFeedbackQuestionnaire')
        allow(Questionnaire).to receive(:find_by).with(id: 1).and_return(questionnaire)
        feedback_response_map = FeedbackResponseMap.new(reviewed_object_id: 1) 
        allow(feedback_response_map).to receive(:questionnaire).and_return(questionnaire)
        expect(questionnaire.questionnaire_type).to eq('AuthorFeedbackQuestionnaire')
      end
    end
end