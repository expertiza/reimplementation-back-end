require 'test_helper'

class StudentTasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_user)
    @headers = { 'Authorization' => "Bearer #{@student.generate_jwt}" }
    @participant = participants(:student_participant)
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
    get list_student_tasks_url  # no headers
    assert_response :unauthorized
  end
end