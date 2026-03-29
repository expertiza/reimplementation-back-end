require 'test_helper'

class RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = users(:super_admin)
    @mentor = users(:postman_flow_mentor)

    # JWT headers for authorized requests
    @headers = { 'Authorization' => "Bearer #{@super_admin.generate_jwt}" }
    @role = roles(:reviewer_role)  # <- change this line only
  end

  test 'admin should get index' do
    get roles_url, headers: @headers
    assert_response :success
    assert_includes @response.body, @role.name
  end

  test 'admin should show role' do
    get role_url(@role), headers: @headers
    assert_response :success
    assert_includes @response.body, @role.name
  end

  test 'admin should create role' do
    post roles_url, params: { role: { name: 'New Role' } }, headers: @headers
    assert_response :created
    assert Role.exists?(name: 'New Role')
  end

  test 'should return error for missing parameters on create' do
    post roles_url, params: { role: {} }, headers: @headers
    assert_response :unprocessable_entity
    assert_includes @response.body, 'Required parameter missing'
  end

  test 'admin should update role' do
    patch role_url(@role), params: { role: { name: 'Updated Role' } }, headers: @headers
    assert_response :success
    @role.reload
    assert_equal 'Updated Role', @role.name
  end

  test 'admin should destroy role' do
    role_to_delete = Role.create!(name: 'Temporary Role')
    assert_difference('Role.count', -1) do
      delete role_url(role_to_delete), headers: @headers
    end
    assert_response :ok
    assert_includes @response.body, 'deleted successfully'
  end

  test 'non-admin cannot access roles' do
    non_admin_headers = { 'Authorization' => "Bearer #{@mentor.generate_jwt}" }
    get roles_url, headers: non_admin_headers
    assert_response :unauthorized
    assert_includes @response.body, 'Not Authorized'
  end

  test 'should get subordinate roles' do
    get subordinate_roles_roles_url, headers: @headers
    assert_response :success
  end
end