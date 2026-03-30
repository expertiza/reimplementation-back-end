class TaskOrdering::BaseTaskTest < ActiveSupport::TestCase
  setup do
    @assignment = assignments(:assignment_one)
    @teams_participant = teams_participants(:teams_participant_one)
    @task = TaskOrdering::BaseTask.new(
      assignment: @assignment,
      team_participant: @teams_participant
    )
  end

  test 'participant returns the participant from teams_participant' do
    assert_equal @teams_participant.participant, @task.participant
  end

  test 'response_map raises NotImplementedError' do
    assert_raises(NotImplementedError) { @task.response_map }
  end

  test 'completed? returns false when no response map' do
    assert_not @task.completed?
  end

  test 'to_task_hash returns expected keys' do
    # response_map raises NotImplementedError on base, so use a subclass
    review_map = response_maps(:student_response_map)
    task = TaskOrdering::ReviewTask.new(
      assignment: @assignment,
      team_participant: @teams_participant,
      review_map: review_map
    )
    hash = task.to_task_hash
    assert_includes hash.keys, :task_type
    assert_includes hash.keys, :assignment_id
    assert_includes hash.keys, :response_map_id
    assert_includes hash.keys, :response_map_type
    assert_includes hash.keys, :reviewee_id
    assert_includes hash.keys, :team_participant_id
  end
end