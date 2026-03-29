require 'test_helper'

class RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = users(:super_admin)
    @headers = { 'Authorization' => "Bearer #{@super_admin.generate_jwt}" }
  end

  test 'should get index' do
    get roles_url, headers: @headers
    assert_response :success
  end

  test 'should show role' do
    role = roles(:admin_role)
    get role_url(role), headers: @headers
    assert_response :success
  end

  test 'should create role' do
    post roles_url, params: { role: { name: 'UniqueRoleTestCreate' } }, headers: @headers
    assert_response :success
    assert Role.exists?(name: 'UniqueRoleTestCreate')
  end

  test 'should update role' do
    role = roles(:ta_role)
    patch role_url(role), params: { role: { name: 'UpdatedTARole' } }, headers: @headers
    assert_response :success
    role.reload
    assert_equal 'UpdatedTARole', role.name
  end

  test 'should destroy role' do
    role = roles(:child_role2)
    assert_difference('Role.count', -1) do
      delete role_url(role), headers: @headers
    end
    assert_response :success
  end
end