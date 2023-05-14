# frozen_string_literal: true
# references to sut refer to the "system under test". This is the target class for the unit test

# Mock implementation of MetareviewResponseMap which can be used in unit tests that have a dependency on this class
class MockMetareviewResponseMap
  attr_accessor :id
end
class ResponseMapTest < ActiveSupport::TestCase

  # verified that instance method returns where a given partipant is the one who performed the meta review
  test "metareviewed_by?" do
    sut = ResponseMap.new
    sut.id = 1
    sut.reviewer = Participant.new
    sut.reviewer.id = 2
    metaReviewer = MockReviewer.new
    metaReviewer.id = 3
    MetareviewResponseMap.stub :where, [MockMetareviewResponseMap.new] do
      assert_equal true, sut.metareviewed_by?(metaReviewer)
    end
  end

  # verified that the instance method returns the correct metareview responsemap when a meta reviewer is assigned
  test "assign_metareviewer" do
    sut = ResponseMap.new
    sut.id = 1
    sut.reviewer = Participant.new
    sut.reviewer.id = 2
    metaReviewer = MockReviewer.new
    metaReviewer.id = 3
    result = MockMetareviewResponseMap.new
    result.id = 5
    MetareviewResponseMap.stub :create, result do
      assert_equal 5, sut.assign_metareviewer(metaReviewer).id
    end
  end

  test "assign_metareviewer_for_round_two" do
    sut = ResponseMap.new
    sut.id = 2
    sut.reviewer = Participant.new
    sut.reviewer.id = 2
    metaReviewer = MockReviewer.new
    metaReviewer.id = 3
    result = MockMetareviewResponseMap.new
    result.id = 2
    MetareviewResponseMap.stub :create, result do
      assert_equal 2, sut.assign_metareviewer(metaReviewer).id
    end
  end

  # verifies that the instance method returns whether a survey is applicable
  test "survey?" do
    sut = ResponseMap.new
    assert_equal false, sut.survey?
  end

  # verfied that the instance method returns the correct assignment team for the response map
  test "reviewee_team" do
    sut = ResponseMap.new
    assignmentTeam = MockAssignmentTeam.new
    assignmentTeam.id = 3

    AssignmentTeam.stub :find, assignmentTeam do
      assert_equal 3, sut.reviewee_team().id
    end
  end

end
