require 'swagger_helper'
require 'rails_helper'

RSpec.describe 'Responses API Controller', type: :request do
  let(:user) { User.new(id: 1, role_id: 1, name: 'no name', full_name: 'no one') }
  let(:team) {Team.new}
  let(:participant) { Participant.new(id: 1, user: user) }
  let(:assignment) { Assignment.new(id: 1, name: 'Test Assignment') }
  let(:answer) { Answer.new(answer: 1, comments: 'Answer text', question_id: 1) }
  let(:question) { ScoredQuestion.new(id: 1, weight: 2) }
  let(:questionnaire) { Questionnaire.new(id: 1, questions: [question], max_question_score: 5) }
  let(:review_response_map) { ReviewResponseMap.new(assignment: assignment, reviewee: team) }
  let(:response_map) { ResponseMap.new(assignment: assignment, reviewee: participant, reviewer: participant) }
  let(:response) { Response.new(map_id: 1, response_map: review_response_map, scores: [answer]) }

  describe "#create" do
    context "when a review already exists for the current stage" do
      it "should edit the existing version" do
        # create necessary objects and set review existing for current stage
        # call create method
        # expect existing version to be edited
      end
    end

    context "when no review exists for the current stage" do
      it "should create a new version" do
        # create necessary objects and set no review existing for current stage
        # call create method
        # expect new version to be created
      end
    end
  end
end