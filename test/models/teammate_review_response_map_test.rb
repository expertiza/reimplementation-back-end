# frozen_string_literal: true
# references to sut refer to the "system under test". This is the target class for the unit test

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

# alternate mock implementation for Assignment, which can be used in unit tests
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

# mock implementation for Questionaire class, which can be be used as dependency in unit tests
class MockQuestionaire
  attr_accessor :questionnaire_id
end

# mock implementation for Reviewer class, which can be be used as dependency in unit tests

class MockReviewer
  attr_accessor :reviewer_id
  attr_accessor :id
end

# mock implementation for TeammateResponse class, which can be be used as dependency in unit tests

class MockTeammateReponse
  def where(query, id)
    3
  end
end


# mock implementation for Participant class, which can be be used as dependency in unit tests
class MockParticipant < Participant
  attr_accessor :user_id
end

# mock implementation for Mailer class, which can be be used as dependency in unit tests

class MockMail
  attr_accessor :deliver
end

class TeammateReviewResponseMapTest < ActiveSupport::TestCase
  # verifies that the instance method returns the proper title for teammate review response maps
  test "title" do
    sut = TeammateReviewResponseMap.new
    assert_equal "Teammate Review", sut.title
  end

  # verifies that the instance method returns the correct questionaire for the associated assignment
  test "questionaire" do
    sut = TeammateReviewResponseMap.new
    sut.assignment = MockAssignment.new

    assert_equal [1,2,3], sut.questionnaire
  end

  # verifies that the instance method returns the correct questionaire for the associated assignment and duty questionaier does not apply
  test "questionnaire_by_duty with nil duty questionaire" do
    sut = TeammateReviewResponseMap.new
    sut.assignment = MockAssignment.new

    AssignmentQuestionnaire.stub :where, [] do
      assert_equal [1,2,3], sut.questionnaire_by_duty(1)
    end
  end

  # verifies that the instance method returns the correct questionaire for the associated assignment and duty questionaire exists
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

  # verfies that the instance method returns the participant who performed the review
  test "contributor" do
    sut = TeammateReviewResponseMap.new
    assert_nil sut.contributor
  end

  # verifies that the instance method returns the correct participant for an associated assignment
  test "reviewer" do
    sut = TeammateReviewResponseMap.new
    reviewer = MockReviewer.new
    reviewer.reviewer_id = 1
    AssignmentParticipant.stub :find, reviewer do
      assert_equal 1, sut.reviewer.reviewer_id
    end
  end

  # verfies that the class method returns the correct report for a given response map id
  test "teammate_response_report" do
    TeammateReviewResponseMap.stub :select, MockTeammateReponse.new do
      assert_equal 3, TeammateReviewResponseMap.teammate_response_report(2)
    end
  end

  # verfies that the instance method creates the correct email command body to be sent to the application mailer
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
