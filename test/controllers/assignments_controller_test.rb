require "test_helper"

class AssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:super_admin)
    @headers = { 'Authorization' => "Bearer #{@user.generate_jwt}" }

    @assignment = assignments(:assignment_one)
  end

  test "should get index" do
    get assignments_url, headers: @headers
    assert_response :success
  end

  test "should show assignment" do
    get assignment_url(@assignment), headers: @headers
    assert_response :success
  end

  test "should create assignment" do
  assert_difference('Assignment.count', 1) do
    post assignments_url, params: {
      assignment: {
        name: "New Assignment",
        directory_path: "new_dir",
        instructor_id: @user.id
      }
    }, headers: @headers
  end
  assert_response :created
end

  test "should update assignment" do
    patch assignment_url(@assignment), params: {
      assignment: { name: "Updated Name" }
    }, headers: @headers
    assert_response :success
    @assignment.reload
    assert_equal "Updated Name", @assignment.name
  end

  test "should destroy assignment" do
    assert_difference('Assignment.count', -1) do
      delete assignment_url(@assignment), headers: @headers
    end
    assert_response :ok
    assert_includes @response.body, "deleted successfully"
  end
end