# frozen_string_literal: true

require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase
  setup do
    @assignment = assignments(:assignment_one)
  end

  test 'valid assignment fixture' do
    assert @assignment.valid?
  end

  test 'should not save without required attributes' do
    assignment = Assignment.new
    assert_not assignment.save
  end

  test 'save review submission task' do
    assignment = @assignment.dup
    assignment.name = "AssignmentReviewTask"
    assert assignment.save
  end

  test 'save quiz submission task' do
    assignment = @assignment.dup
    assignment.name = "AssignmentQuizTask"
    assert assignment.save
  end
end