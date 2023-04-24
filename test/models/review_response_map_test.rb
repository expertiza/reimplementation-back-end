# frozen_string_literal: true
# references to sut refer to the "system under test". This is the target class for the unit test

# mock implementation for AssignmentTeam class which can be used in unit test dependency mocking
class MockAssignmentTeam
  attr_accessor :test_id
  attr_accessor :parent_id
  attr_accessor :id
end

class MockAssignmentTeam
  def users
    []
  end
end

class ReviewResponseMapTest < ActiveSupport::TestCase
  # verifies that instance method returns the correct title for the review response map instance
  test "title" do
    sut = ReviewResponseMap.new
    assert_equal "Review", sut.title
  end

  # verifies that the instance method returns the associated questionaire for a given assignment
  test "questionaire" do
    sut = ReviewResponseMap.new
    questionaire = MockQuestionaire.new
    questionaire.questionnaire_id = 3999
    sut.assignment = MockAssignment.new

    Questionnaire.stub :find, questionaire do
      assert_equal 3999, sut.questionnaire().questionnaire_id
    end
  end

  # verifies that instance method returns the correct export fields
  test "export_fields" do
    assert_equal ['contributor', 'reviewed by'], ReviewResponseMap.export_fields
  end

  # verfies that the instance method return properly when there is no response associated with the respnse map
  test "show_feedback returning nil when there is no response" do
    sut = ReviewResponseMap.new
    assert_nil sut.show_feedback(nil)
  end

  # verfies that the instance method returns correctly when there are no meta reviews completed
  test "metareview_response_maps" do
    sut = ReviewResponseMap.new
    Response.stub :where, [] do
      assert_equal [], sut.metareview_response_maps
    end
  end

  # verfies that the instance method returns the correct reviewer for a given assignment & team
  test "reviewer" do
    sut = ReviewResponseMap.new
    assignment = MockAssignment.new
    assignment.team_reviewing_enabled = true
    assignment.id = 1
    sut.assignment = assignment
    assignment_team = MockAssignmentTeam.new
    assignment_team.test_id = 'testId'
    Assignment.stub :find, assignment do
      AssignmentTeam.stub :find, assignment_team do
        assert_equal 'testId', sut.reviewer.test_id
      end
    end
  end

  # verifies that the class method returns the correct reviewer for a given assignment
  test "reviewer_with_id" do
    assignment = MockAssignment.new
    assignment.team_reviewing_enabled = true
    assignment.id = 1
    assignment_team = MockAssignmentTeam.new
    assignment_team.test_id = 'testId'
    Assignment.stub :find, assignment do
      AssignmentTeam.stub :find, assignment_team do
        assert_equal 'testId', ReviewResponseMap.reviewer_by_id(assignment.id, 3).test_id
      end
    end
  end

  # verfies that the class method returns the correct set of versions for a given assignment
  test "final_versions_from_reviewer" do
    assignment = MockAssignment2.new
    assignment.team_reviewing_enabled = true
    assignment.id = 1
    assignment_team = MockAssignmentTeam.new
    assignment_team.test_id = 'testId'
    assignment_team.parent_id = 'parentId'
    Assignment.stub :find, assignment do
      AssignmentTeam.stub :find, assignment_team do
        result = ReviewResponseMap.final_versions_from_reviewer(0, 0)
        assert_equal 2, result[:review][:questionnaire_id]
      end
    end
  end

  # verified that the instance method creates the expect email body to be sent to the application mailer
  test "email" do
    sut = ReviewResponseMap.new
    assignmentTeam = MockAssignmentTeam.new
    assignment = MockAssignment.new
    assignment.name = "test case assignment"
    defn = {body: {}}
    AssignmentTeam.stub :find, assignmentTeam do
      ApplicationMailer.stub :sync_message, MockMail.new do
        sut.send_email(defn, assignment)
        assert_equal 'Peer Review', defn[:body][:type]
      end
    end
  end

  # verifies that the class method returns the expected data structure for final reviews
  test "prepare_final_review_versions" do
    assignment = MockAssignment2.new
    assignment.team_reviewing_enabled = true
    assignment.id = 1
    result = ReviewResponseMap.prepare_final_review_versions(assignment, [])
    assert_equal 2, result[:review][:questionnaire_id]
  end
end
