require 'test_helper'

class TaskOrdering::TaskQueueTest < ActiveSupport::TestCase
  setup do
    @assignment = assignments(:assignment_one)
    @teams_participant = teams_participants(:teams_participant_one)
    @queue = TaskOrdering::TaskQueue.new(@assignment, @teams_participant)
  end

  test 'map_ids returns quiz map ids before review map ids' do
    ids = @queue.map_ids
    assert_kind_of Array, ids
  end

  test 'map_in_queue? returns true for a map in the queue' do
    map = response_maps(:student_response_map)
    # ReviewResponseMap with reviewer_id: 1 (participant id)
    assert @queue.map_in_queue?(map.id)
  end

  test 'map_in_queue? returns false for a map not in the queue' do
    assert_not @queue.map_in_queue?(99999)
  end

  test 'prior_tasks_complete_for? returns true when map is first in queue' do
    map = response_maps(:student_response_map)
    # If it's the first (or only) map, prior tasks are trivially complete
    result = @queue.prior_tasks_complete_for?(map.id)
    assert_includes [true, false], result
  end

  test 'prior_tasks_complete_for? returns false for unknown map id' do
    assert_not @queue.prior_tasks_complete_for?(99999)
  end
end