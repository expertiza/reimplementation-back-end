RSpec.describe BookmarkRatingResponseMap, type: :model do
  describe '#questionnaire' do
    it 'returns associated questionnaire' do
      questionnaire = Questionnaire.new
      assignment = Assignment.new
      bookmark_rating_response_map = BookmarkRatingResponseMap.new
      allow(bookmark_rating_response_map).to receive(:assignment).and_return(assignment)
      allow(questionnaire).to receive(:where).with(type: 'BookmarkRatingResponseMap').and_return(questionnaire)
      expect(bookmark_rating_response_map.questionnaire).to eq(questionnaire)
    end
  end


  describe '#self.bookmark_response_report(assignment_id)' do
    let(:assignment) { Assignment.create(id: 1, name: 'Test Assignment', instructor:) }
    let(:reviewee) { create(:reviewee, assignment: assignment) }
    let(:bookmark_rating_response_map) { double('BookmarkRatingResponseMap') }
    before do
      allow(bookmark_rating_response_map).to receive(:assignment).and_return(double('Assignment'))
      allow(bookmark_rating_response_map).to receive(:reviewed_object_id).and_return(double('id'))
    end

    it 'returns the list of reviewer IDs for a given assignment ID' do
      bookmark_rating_response_map.create(reviewer_id: 1, reviewed_object_id: assignment.assignment_id)
      bookmark_rating_response_map.create(reviewer_id: 2, reviewed_object_id: assignment.assignment_id)

      expect(BookmarkRatingResponseMap.bookmark_response_report(assignment.assignment_id)).to eq([1, 2])
    end

    it 'returns an empty array if no bookmark ratings exist for the given assignment ID' do
      expect(BookmarkRatingResponseMap.bookmark_response_report(assignment.assignment_id)).to be_empty
    end

    it 'returns a distinct list of reviewer IDs' do
      bookmark_rating_response_map.create(reviewer_id: 1, reviewed_object_id: assignment.assignment_id)
      bookmark_rating_response_map.create(reviewer_id: 2, reviewed_object_id: assignment.assignment_id)

      expect(BookmarkRatingResponseMap.bookmark_response_report(assignment.assignment_id).size).to eq(2)
    end
  end
end