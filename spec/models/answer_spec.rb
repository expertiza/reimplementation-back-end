require '/Users/aw/Documents/Course Study Material/OODD/Program 3/spec/rails_helper.rb'
require '/Users/aw/Documents/Course Study Material/OODD/Program 3/spec/spec_helper.rb'

RSpec.describe Answer, type: :model do
  describe ".by_question_for_reviewee_in_round" do
    let(:assignment) { create(:assignment) }
    let(:reviewer) { create(:user) }
    let(:reviewee) { create(:user) }
    let(:round) { 1 }
    let(:question) { create(:question, assignment: assignment) }
    let(:response_map) { create(:review_map, reviewed_object: assignment, reviewer: reviewer, reviewee: reviewee) }
    let(:response) { create(:response, map: response_map, round: round) }
    let!(:answer) { create(:answer, question: question, response: response) }

    it "returns the answer and comments for the specified question, reviewee, assignment, and round" do
      expect(Answer.by_question_for_reviewee_in_round(assignment.id, reviewee.id, question.id, round))
        .to match_array([{answer: answer.answer, comments: answer.comments}])
    end
  end

  describe ".by_question" do
    let(:assignment) { create(:assignment) }
    let(:reviewer) { create(:user) }
    let(:question) { create(:question, assignment: assignment) }
    let(:response_map) { create(:review_map, reviewed_object: assignment, reviewer: reviewer) }
    let(:response) { create(:response, map: response_map) }
    let!(:answer) { create(:answer, question: question, response: response) }

    it "returns the answer and comments for the specified question and assignment" do
      expect(Answer.by_question(assignment.id, question.id))
        .to match_array([{answer: answer.answer, comments: answer.comments}])
    end
  end

  describe ".by_question_for_reviewee" do
    let(:assignment) { create(:assignment) }
    let(:reviewer) { create(:user) }
    let(:reviewee) { create(:user) }
    let(:question) { create(:question, assignment: assignment) }
    let(:response_map) { create(:review_map, reviewed_object: assignment, reviewer: reviewer, reviewee: reviewee) }
    let(:response) { create(:response, map: response_map) }
    let!(:answer) { create(:answer, question: question, response: response) }

    it "returns the answer and comments for the specified question, reviewee, and assignment" do
      expect(Answer.by_question_for_reviewee(assignment.id, reviewee.id, question.id))
        .to match_array([{answer: answer.answer, comments: answer.comments}])
    end
  end

  describe ".by_response" do
    let(:response) { create(:response) }
    let!(:answer) { create(:answer, response: response) }

    it "returns the answer for the specified response" do
      expect(Answer.by_response(response.id)).to eq([answer.answer])
    end
  end
end
