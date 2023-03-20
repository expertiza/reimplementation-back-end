# frozen_string_literal: true

class MockResponse < Response
  attr_accessor :map_id

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

class MockResponseMap
  attr_accessor :reviewee
  attr_accessor :assignment
  attr_accessor :reviewer_id
end

class FeedbackResponseMapTest < ActiveSupport::TestCase
  test "assignment" do
    sut = FeedbackResponseMap.new
    sut.review = MockResponse.new
    assert_equal 3, sut.assignment.id
  end

  test "show_review" do
    sut = FeedbackResponseMap.new
    assert_equal "No review was performed", sut.show_review
  end

  test "title" do
    sut = FeedbackResponseMap.new
    assert_equal "Feedback", sut.title
  end

  test "questionnaire" do
    sut = FeedbackResponseMap.new
    sut.review = MockResponse.new
    assert_equal [1,2,3], sut.questionnaires
  end

  test "contributor" do
    sut = FeedbackResponseMap.new
    sut.review = MockResponse.new
    assert_equal 5, sut.contributor.id
  end

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
