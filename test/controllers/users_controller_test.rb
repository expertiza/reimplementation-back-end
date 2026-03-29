require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = users(:super_admin)
    @headers = { 'Authorization' => "Bearer #{@super_admin.generate_jwt}" }
  end

  test 'should get index' do
    get users_url, headers: @headers
    assert_response :success
  end

  test 'should show user' do
    user = users(:postman_flow_mentor)
    get user_url(user), headers: @headers
    assert_response :success
  end

  test 'should create user' do
    post users_url, params: { user: { name: 'NewUserTest', full_name: 'New User', email: 'newuser@example.com', password: 'password123', role_id: roles(:student_role).id } }, headers: @headers
    assert_response :success
    assert User.exists?(email: 'newuser@example.com')
  end

  test 'should update user' do
    user = users(:postman_flow_reviewer)
    patch user_url(user), params: { user: { full_name: 'Updated Reviewer' } }, headers: @headers
    assert_response :success
    user.reload
    assert_equal 'Updated Reviewer', user.full_name
  end

  test 'should destroy user' do
    user = users(:postman_flow_reviewer)
    assert_difference('User.count', -1) do
      delete user_url(user), headers: @headers
    end
    assert_response :success
  end
end