require 'test_helper'

class StudentTasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_user)
    @headers = { 'Authorization' => "Bearer #{@student.generate_jwt}" }
    @participant = participants(:student_participant)
    @assignment = assignments(:assignment_one)
    @response_map = response_maps(:student_response_map)
  end

  test 'should get list of student tasks' do
    get list_student_tasks_url, headers: @headers
    assert_response :success
  end

  test 'should show student task by participant id' do
    get view_student_tasks_url, params: { id: @participant.id }, headers: @headers
    assert_response :success
  end

  test 'unauthenticated user cannot access student tasks' do
    get list_student_tasks_url
    assert_response :unauthorized
  end

  test 'should get queue for assignment' do
    get queue_student_tasks_url, params: { assignment_id: @assignment.id }, headers: @headers
    assert_response :success
  end

  test 'should return not found for unknown assignment in queue' do
    get queue_student_tasks_url, params: { assignment_id: 99999 }, headers: @headers
    assert_response :not_found
  end

  test 'should get next task for assignment' do
    get next_task_student_tasks_url, params: { assignment_id: @assignment.id }, headers: @headers
    assert_response :success
  end

  test 'should return not found for unknown assignment in next_task' do
    get next_task_student_tasks_url, params: { assignment_id: 99999 }, headers: @headers
    assert_response :not_found
  end

  test 'should start task with valid response map' do
    post start_task_student_tasks_url, params: { response_map_id: @response_map.id }, headers: @headers
    assert_response :success
  end

  test 'should return not found for invalid response map on start_task' do
    post start_task_student_tasks_url, params: { response_map_id: 99999 }, headers: @headers
    assert_response :not_found
  end
end
