require 'rails_helper'

RSpec.describe ResponseMap, type: :model do
  let(:user) { User.new(id: 1, role_id: 1, name: 'no name', fullname: 'no one') }
  let(:team) {Team.new}
  let(:participant) { Participant.new(id: 1) }
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:participant) { Participant.new(id: 1, user: user) }
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  let(:question) { ScoredQuestion.new(id: 1, weight: 2) }
  let(:questionnaire) { Questionnaire.new(id: 1, questions: [question], max_question_score: 5) }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  let(:response_map) { ResponseMap.new(assignment: assignment, reviewee: participant, reviewer: participant) }

  describe ".get_all_responses" do
    it "returns all responses by a particular reviewer" do
      response_map = ReviewResponseMap.create!(assignment: assignment, reviewer: participant, reviewee: team)

      response1 = Response.create!(response_map: response_map)
      response2 = Response.create!(response_map: response_map)

      expect(response_map.get_all_responses).to eq([response1, response2])
    end
  end

  describe ".response_assignment" do
    it 'returns the appropriate assignment for ResponseMap' do
      allow(Participant).to receive(:find).and_return(participant)
      allow(participant).to receive(:assignment).and_return(assignment)

      expect(response_map.response_assignment).to eq(assignment)
    end
  end
end
