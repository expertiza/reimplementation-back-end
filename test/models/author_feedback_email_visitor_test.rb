# frozen_string_literal: true
# references to sut refer to the "system under test". This is the target class for the unit test

class AuthorFeedbackEmailVisitorTest < ActiveSupport::TestCase

  # verify that visitor visit method enriches mail command definition, which will be passed to mailer instance
  test "visit" do
    sut = AuthorFeedbackEmailVisitor.new
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
    mail = AuthorFeedbackEmailSendingMethod.new(defn, assignment, 1)
    Response.stub :find, response do
      ResponseMap.stub :find, response_map do
        AssignmentParticipant.stub :find, participant do
          User.stub :find, user do
            ApplicationMailer.stub :sync_message, MockMail.new do
              sut.visit(mail)
              assert_equal 'Author Feedback', defn[:body][:type]
            end
          end
        end
      end
    end
  end
end
