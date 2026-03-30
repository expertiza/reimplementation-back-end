# test/controllers/duties_controller_test.rb
require 'test_helper'

class DutiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @instructor = users(:postman_flow_mentor)
    @headers = { 'Authorization' => "Bearer #{@instructor.generate_jwt}" }
    @duty = duties(:duty_one)
  end

  # GET /duties
  test 'instructor should get index' do
    get duties_url, headers: @headers
    assert_response :success
  end

  test 'instructor can filter duties by search' do
    get duties_url, params: { search: 'Test' }, headers: @headers
    assert_response :success
  end

  test 'instructor can filter own duties with mine param' do
    get duties_url, params: { mine: true }, headers: @headers
    assert_response :success
  end

  # GET /duties/:id
  test 'instructor should show own duty' do
    get duty_url(@duty), headers: @headers
    assert_response :success
  end

  test 'instructor cannot view another instructors private duty' do
    get duty_url(duties(:private_duty)), headers: @headers
    assert_response :forbidden
  end

  # POST /duties
  test 'instructor should create duty' do
    assert_difference('Duty.count', 1) do
      post duties_url, params: { duty: { name: 'New Duty', private: false } }, headers: @headers
    end
    assert_response :created
  end

  test 'should not create duty with missing name' do
    post duties_url, params: { duty: { name: '' } }, headers: @headers
    assert_response :unprocessable_entity
  end

  # PATCH /duties/:id
  test 'instructor should update own duty' do
    patch duty_url(@duty), params: { duty: { name: 'Updated Duty' } }, headers: @headers
    assert_response :success
    @duty.reload
    assert_equal 'Updated Duty', @duty.name
  end

  test 'instructor cannot update another instructors duty' do
    patch duty_url(duties(:private_duty)), params: { duty: { name: 'Hacked' } }, headers: @headers
    assert_response :forbidden
  end

  # DELETE /duties/:id
  test 'instructor should destroy own duty' do
    assert_difference('Duty.count', -1) do
      delete duty_url(@duty), headers: @headers
    end
    assert_response :no_content
  end

  test 'instructor cannot destroy another instructors duty' do
    delete duty_url(duties(:private_duty)), headers: @headers
    assert_response :forbidden
  end

  # GET /duties/accessible_duties
  test 'should get accessible duties' do
    get accessible_duties_duties_url, headers: @headers
    assert_response :success
  end

  # Non-instructor access
  test 'non-instructor cannot access duties' do
    student_headers = { 'Authorization' => "Bearer #{users(:student_user).generate_jwt}" }
    get duties_url, headers: student_headers
    assert_response :forbidden
  end
end