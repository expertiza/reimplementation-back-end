RSpec.describe BookmarkRatingResponseMap, type: :model do
  describe '#questionnaire' do
    it 'returns associated questionnaire' do
      questionnaire = Questionnaire.new
      assignment = Assignment.new
      bookmark_rating_response_map = BookmarkRatingResponseMap.new
      allow(bookmark_rating_response_map).to receive(:assignment).and_return(assignment)
      allow(assignment).to receive_message_chain(:questionnaires, :where).with(type: 'BookmarkRatingResponseMap').and_return(questionnaire)
      expect(bookmark_rating_response_map.questionnaire).to eq(questionnaire)
    end
  end


  describe '#self.bookmark_response_report(assignment_id)' do
    it 'returns an empty array if no bookmark ratings exist for the given assignment ID' do
      assignment = double('Assignment', assignment_id: 1)
      bookmark_rating_response_map = BookmarkRatingResponseMap.new(reviewed_object_id: 1)

      allow(bookmark_rating_response_map).to receive(:assignment).and_return(assignment)
      allow(bookmark_rating_response_map).to receive(:reviewed_object_id).and_return(assignment)
      expect(bookmark_rating_response_map.bookmark_response_report(assignment.assignment_id)).to be_empty
    end

    it 'returns a distinct list of reviewer IDs' do
      assignment = double('Assignment', assignment_id: 1)
      bookmark_rating_response_map = BookmarkRatingResponseMap.new(reviewed_object_id: 1)

      allow(bookmark_rating_response_map).to receive(:assignment).and_return(assignment)
      allow(bookmark_rating_response_map).to receive(:reviewed_object_id).and_return(assignment)
      expect(bookmark_rating_response_map.bookmark_response_report(assignment.assignment_id).size).to eq(2)
    end
  end
end