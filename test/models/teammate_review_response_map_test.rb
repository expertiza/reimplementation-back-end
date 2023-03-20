# frozen_string_literal: true

require 'test_helper'

# Mock implementation for Assignment which is used in unit test assertions
class MockAssignment < Assignment
  def questionnaires
    MockQuestionaires.new
  end

  def review_questionnaire_id(round, topic)
    3
  end

  attr_accessor :team_reviewing_enabled
end

class MockAssignment2 < MockAssignment
  def review_questionnaire_id(round)
    2
  end
end


# mocking the Questionaire class with arbitrary return values to support assertions in tests
class MockQuestionaires
  def find_by(type)
    [1,2,3]
  end
end

class MockQuestionaire
  attr_accessor :questionnaire_id
end

class MockReviewer
  attr_accessor :reviewer_id
  attr_accessor :id
end

class MockTeammateReponse
  def where(query, id)
    3
  end
end

class MockParticipant
  attr_accessor :user_id
end

class MockMail
  attr_accessor :deliver
end

class TeammateReviewResponseMapTest < ActiveSupport::TestCase
  test "title" do
    sut = TeammateReviewResponseMap.new
    assert_equal "Teammate Review", sut.title
  end

  test "questionaire" do
    sut = TeammateReviewResponseMap.new
    sut.assignment = MockAssignment.new

    assert_equal [1,2,3], sut.questionnaire
  end

  test "questionnaire_by_duty with nil duty questionaire" do
    sut = TeammateReviewResponseMap.new
    sut.assignment = MockAssignment.new

    AssignmentQuestionnaire.stub :where, [] do
      assert_equal [1,2,3], sut.questionnaire_by_duty(1)
    end
  end

  test "questionnaire_by_duty with not nil duty questionaire" do
    sut = TeammateReviewResponseMap.new
    sut.assignment = MockAssignment.new
    questionaire = MockQuestionaire.new
    questionaire.questionnaire_id = 1
    questionaire2 = MockQuestionaire.new
    questionaire2.questionnaire_id = 2
    AssignmentQuestionnaire.stub :where, [questionaire] do
      Questionnaire.stub :find, questionaire2 do
        assert_equal 2, sut.questionnaire_by_duty(1).questionnaire_id
      end
    end
  end

  test "contributor" do
    sut = TeammateReviewResponseMap.new
    assert_equal nil, sut.contributor
  end

  test "reviewer" do
    sut = TeammateReviewResponseMap.new
    reviewer = MockReviewer.new
    reviewer.reviewer_id = 1
    AssignmentParticipant.stub :find, reviewer do
      assert_equal 1, sut.reviewer.reviewer_id
    end
  end

  test "teammate_response_report" do
    TeammateReviewResponseMap.stub :select, MockTeammateReponse.new do
      assert_equal 3, TeammateReviewResponseMap.teammate_response_report(2)
    end
  end

  test "email" do
    sut = TeammateReviewResponseMap.new
    defn = {body: {}}
    assignment = MockAssignment.new
    assignment.name = "test case assignment"
    participant = MockParticipant.new
    user = User.new
    user.fullname = "testcase user"
    user.email = "testcaseuser@ncsu.edu"
    AssignmentParticipant.stub :find, participant do
      User.stub :find, user do
        ApplicationMailer.stub :sync_message, MockMail.new do
          sut.send_email(defn, assignment)
          assert_equal 'Teammate Review', defn[:body][:type]
          assert_equal "test case assignment", defn[:body][:obj_name]
        end
      end
    end
  end
end
