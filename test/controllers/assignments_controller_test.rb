require 'test_helper'

class AssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = users(:super_admin)
    @headers = { 'Authorization' => "Bearer #{@super_admin.generate_jwt}" }
    @assignment = assignments(:assignment_one)
  end

  test 'should get index' do
    get assignments_url, headers: @headers
    assert_response :success
  end

  test 'should show assignment' do
    get assignment_url(@assignment), headers: @headers
    assert_response :success
  end

  test 'should create assignment' do
    post assignments_url, params: { assignment: { name: 'UniqueAssignmentTest', directory_path: 'dir_test', course_id: 1, instructor_id: @super_admin.id, submitter_count: 1 } }, headers: @headers
    assert_response :success
    assert Assignment.exists?(name: 'UniqueAssignmentTest')
  end

  test 'should update assignment' do
    patch assignment_url(@assignment), params: { assignment: { name: 'UpdatedAssignmentTest' } }, headers: @headers
    assert_response :success
    @assignment.reload
    assert_equal 'UpdatedAssignmentTest', @assignment.name
  end

  test 'should destroy assignment' do
    assert_difference('Assignment.count', -1) do
      delete assignment_url(@assignment), headers: @headers
    end
    assert_response :success
  end
end