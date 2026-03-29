class TaskOrdering::ReviewTaskTest < ActiveSupport::TestCase
  setup do
  @assignment = assignments(:assignment_one)
  @teams_participant = teams_participants(:teams_participant_one)
  @review_map = response_maps(:student_response_map)
  @task = TaskOrdering::ReviewTask.new(
    assignment: @assignment,
    team_participant: @teams_participant,
    review_map: @review_map
  )
  Response.where(map_id: @review_map.id).delete_all  # clear fixture response
end

  test 'task_type is :review' do
    assert_equal :review, @task.task_type
  end

  test 'response_map returns the review map' do
    assert_equal @review_map, @task.response_map
  end

  test 'completed? returns false when no submitted response' do
    assert_not @task.completed?
  end

  test 'completed? returns true when response is submitted' do
    Response.create!(map_id: @review_map.id, round: 1, is_submitted: true)
    assert @task.completed?
  end

  test 'ensure_response! creates a response if none exists' do
    assert_difference('Response.count', 1) do
      @task.ensure_response!
    end
  end

  test 'ensure_response! does not duplicate responses' do
    @task.ensure_response!
    assert_no_difference('Response.count') do
      @task.ensure_response!
    end
  end
end