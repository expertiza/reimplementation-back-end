# frozen_string_literal: true
# references to sut refer to the "system under test". This is the target class for the unit test

class TeammateReviewEmailVisitorTest < ActiveSupport::TestCase

  # verify that visitor visit method enriches mail command definition, which will be passed to mailer instance
  test "visit" do
    sut = TeammateReviewEmailVisitor.new
    defn = {body: {}}
    assignment = MockAssignment.new
    assignment.name = "test case assignment"
    participant = MockParticipant.new
    user = User.new
    user.fullname = "testcase user"
    user.email = "testcaseuser@ncsu.edu"
    mail = TeammateReviewEmailSender.new(defn, assignment, 1)
    AssignmentParticipant.stub :find, participant do
      User.stub :find, user do
        ApplicationMailer.stub :sync_message, MockMail.new do
          sut.visit(mail)
          assert_equal 'Teammate Review', defn[:body][:type]
          assert_equal "test case assignment", defn[:body][:obj_name]
        end
      end
    end
  end
end
