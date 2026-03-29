class TaskOrdering::TaskFactoryTest < ActiveSupport::TestCase
  setup do
    @assignment = assignments(:assignment_one)
    @teams_participant = teams_participants(:teams_participant_one)
  end

  test 'build returns empty array when no review maps and no quiz' do
    tasks = TaskOrdering::TaskFactory.build(
      assignment: @assignment,
      team_participant: @teams_participant
    )
    assert_kind_of Array, tasks
  end

  test 'allows_review? returns true for reviewer duty' do
    duty = Duty.new(name: 'reviewer')
    assert TaskOrdering::TaskFactory.allows_review?(duty)
  end

  test 'allows_review? returns false for submitter duty' do
    duty = Duty.new(name: 'submitter')
    assert_not TaskOrdering::TaskFactory.allows_review?(duty)
  end

  test 'allows_review? returns false for nil duty' do
    assert_not TaskOrdering::TaskFactory.allows_review?(nil)
  end

  test 'allows_quiz? returns true for reader duty' do
    duty = Duty.new(name: 'reader')
    assert TaskOrdering::TaskFactory.allows_quiz?(duty)
  end

  test 'allows_quiz? returns false for reviewer duty' do
    duty = Duty.new(name: 'reviewer')
    assert_not TaskOrdering::TaskFactory.allows_quiz?(duty)
  end

  test 'allows_quiz? returns false for nil duty' do
    assert_not TaskOrdering::TaskFactory.allows_quiz?(nil)
  end

  test 'allows_submit? returns true for submitter duty' do
    duty = Duty.new(name: 'submitter')
    assert TaskOrdering::TaskFactory.allows_submit?(duty)
  end

  test 'allows_submit? returns false for reviewer duty' do
    duty = Duty.new(name: 'reviewer')
    assert_not TaskOrdering::TaskFactory.allows_submit?(duty)
  end

  test 'allows_submit? returns false for nil duty' do
    assert_not TaskOrdering::TaskFactory.allows_submit?(nil)
  end
end