# frozen_string_literal: true
# references to sut refer to the "system under test". This is the target class for the unit test

# Mock implementation for the Response class, which is used in various test scenarios where an Response instance is required
class MockResponse < Response
  attr_accessor :map_id

  def each

  end
  def map
    responseMap = MockResponseMap.new
    mockAssignment = MockAssignment.new
    mockAssignment.id = 3
    responseMap.assignment = mockAssignment
    mockReviewee = Participant.new
    mockReviewee.id = 5
    responseMap.reviewee = mockReviewee
    return responseMap
  end
end

# simple mock response map class, which can be used for unit test assertions
class MockResponseMap
  attr_accessor :reviewee
  attr_accessor :assignment
  attr_accessor :reviewer_id
end

class FeedbackResponseMapTest < ActiveSupport::TestCase
  # verifies public instance method returns the assignment associated with a review
  test "assignment" do
    sut = FeedbackResponseMap.new
    sut.review = [MockResponse.new]
    sut.review.stub :map, MockResponse.new.map do
      assert_equal 3, sut.assignment.id
    end
  end

  # verifies instance method returns a feedback response maps title
  test "title" do
    sut = FeedbackResponseMap.new
    assert_equal "Feedback", sut.title
  end

  # verifies that the instance method returns the questionaire associated with the review
  test "author_feedback_questionnaire" do
    sut = FeedbackResponseMap.new
    sut.review = [MockResponse.new]
    sut.review.stub :map, MockResponse.new.map do
      assert_equal [1,2,3], sut.author_feedback_questionnaire
    end
  end

  # verfies that the instance method returns the participant who performed the review
  test "contributor" do
    sut = FeedbackResponseMap.new
    sut.review = [MockResponse.new]
    sut.review.stub :map, MockResponse.new.map do
      assert_equal 5, sut.contributor.id
    end
  end

  # verfies that the instance method creates the correct email command body to be sent to the application mailer
  test "email" do
    sut = FeedbackResponseMap.new
    response = MockResponse.new
    response.map_id = 3
    response_map = MockResponseMap.new
    response_map.reviewer_id = 4
    participant = MockParticipant.new
    participant.user_id = 33
    assignment = MockAssignment.new
    assignment.name = "test case assignment"
    user = User.new
    user.email = "testuser@ncsu.edu"

    defn = {body: {}}
    Response.stub :find, response do
      ResponseMap.stub :find, response_map do
        AssignmentParticipant.stub :find, participant do
          User.stub :find, user do
            ApplicationMailer.stub :sync_message, MockMail.new do
              sut.send_email(defn, assignment)
              assert_equal 'Author Feedback', defn[:body][:type]
            end
          end
        end
      end
    end
  end
end
