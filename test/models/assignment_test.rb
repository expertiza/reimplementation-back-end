require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase
  def setup
    @assignment = Assignment.new(
      name: "Final Project",
      description: "Complete the final project for the course.",
      due_date: 1.week.from_now
    )
  end

  # Test Valid Assignment
  test "should be valid" do
    assert @assignment.valid?
  end

  # Test Name Presence
  test "should not save assignment without a name" do
    @assignment.name = nil
    assert_not @assignment.valid?
  end

  # Test Description Presence
  test "should not save assignment without a description" do
    @assignment.description = nil
    assert_not @assignment.valid?
  end

  # Test Due Date Presence
  test "should not save assignment without a due date" do
    @assignment.due_date = nil
    assert_not @assignment.valid?
  end

  # Test Due Date Validity (Past Dates)
  test "should not allow past due dates" do
    @assignment.due_date = 1.day.ago
    assert_not @assignment.valid?
  end

  # Test Associations (Assuming Assignment belongs to a Course)
  test "should belong to a course" do
    assert_respond_to @assignment, :course
  end

  # Test Scope (Assuming a scope `upcoming` exists)
  test "should return upcoming assignments" do
    @assignment.save
    assert_includes Assignment.upcoming, @assignment
  end

  # Test Custom Method (If there's a method `overdue?`)
  test "should be overdue if due date has passed" do
    @assignment.due_date = 1.day.ago
    @assignment.save
    assert @assignment.overdue?
  end
end
