RSpec.describe TeammateReviewResponseMap, type: :model do
  let(:teammate_review_response_map) { TeammateReviewResponseMap.new reviewer: participant, team_reviewing_enabled: true, assignment: assignment }
  let(:role) {Role.create(name: 'Instructor', parent_id: nil, id: 2, default_page_id: nil)}
  let(:instructor) { Instructor.create(instructor_id: 1234, name: 'testinstructor', email: 'test@test.com', full_name: 'Test Instructor', password: '123456', role: role) }
  let(:assignment) { build(:assignment, id: 1, name: 'Test Assgt', rounds_of_reviews: 2, instructor: instructor, course: Course.new) }
  let(:questionnaire) { Questionnaire.new name: 'abc', private: 0, min_question_score: 0, max_question_score: 10, instructor_id: 1234 }
  let(:assignment_questionnaire) { build(:questionnaire, id: 1, assignment_id: 1, questionnaire_id: 2, duty_id: 1, instructor_id: 1234) }


  describe '#questionnaire' do
    it 'returns associated questionnaire' do
      questionnaire = double('Questionnaire')
      assignment = double('Assignment')
      teammate_review_response_map = TeammateReviewResponseMap.new
      allow(teammate_review_response_map).to receive(:assignment).and_return(assignment)
      allow(AssignmentQuestionnaire).to receive(:where).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)
      expect(teammate_review_response_map.questionnaire).to eq(questionnaire)
    end
  end

  describe '#questionnaire_by_duty' do
    it 'returns questionnaire specific to a duty' do
      allow(AssignmentQuestionnaire).to receive(:find).with(assignment_id: 1, duty_id: 1).and_return([assignment_questionnaire])
      expect(teammate_review_response_map.questionnaire_by_duty(1)).to eq questionnaire
    end
    it 'returns default questionnaire when no questionnaire is found for duty' do
      allow(AssignmentQuestionnaire).to receive(:where).with(assignment_id: 1, duty_id: 1).and_return([])
      allow(assignment).to receive(:questionnaires).and_return(questionnaire)
      allow(AssignmentQuestionnaire).to receive(:where).with(type: 'TeammateReviewQuestionnaire').and_return(questionnaire)
      expect(teammate_review_response_map.questionnaire_by_duty(1)).to eq questionnaire
    end
  end
end