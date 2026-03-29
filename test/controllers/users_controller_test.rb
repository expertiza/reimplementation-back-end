require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = users(:super_admin)
    @mentor = users(:postman_flow_mentor)
    @reviewer = users(:postman_flow_reviewer)

    # JWT authorization header
    @headers = { 'Authorization' => "Bearer #{@super_admin.generate_jwt}" }
  end

  test 'should get index' do
    get users_url, headers: @headers
    assert_response :success
    assert_includes @response.body, @super_admin.email
  end

  test 'should show a user' do
    get user_url(@mentor), headers: @headers
    assert_response :success
    assert_includes @response.body, @mentor.email
  end

  test 'should create a user' do
    post users_url,
         params: { user: { name: 'new_user', full_name: 'New User', email: 'newuser@example.com',
                           password: 'password123', role_id: roles(:reviewer_role).id } },
         headers: @headers

    assert_response :created
    assert User.exists?(email: 'newuser@example.com')
  end

  test 'should return error for missing parameters on create' do
    post users_url, params: { user: { name: 'incomplete_user' } }, headers: @headers
    assert_response :unprocessable_entity
    assert_includes @response.body, "can't be blank"
  end

  test 'should update a user' do
    patch user_url(@reviewer), params: { user: { full_name: 'Updated Reviewer' } }, headers: @headers
    assert_response :success
    @reviewer.reload
    assert_equal 'Updated Reviewer', @reviewer.full_name
  end

  test 'should destroy a user' do
    assert_difference('User.count', -1) do
      delete user_url(@reviewer), headers: @headers
    end
    assert_response :no_content
  end

  test 'should return 404 for non-existent user' do
    get user_url(id: 99999), headers: @headers
    assert_response :not_found
    assert_includes @response.body, 'User with id 99999 not found'
  end
end