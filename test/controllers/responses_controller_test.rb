require 'test_helper'

class ResponsesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student = users(:student_user)
    @headers = { 'Authorization' => "Bearer #{@student.generate_jwt}" }
    @response_map = response_maps(:student_response_map)
    @response_record = responses(:response_one)
  end

  test 'should create response' do
    post responses_url, params: {
      response_map_id: @response_map.id,
      round: 1,
      content: '{}'
    }, headers: @headers
    assert_response :created
  end

  test 'should show response' do
    get response_url(@response_record), headers: @headers
    assert_response :success
  end

  test 'should update response' do
    patch response_url(@response_record), params: {
      is_submitted: true
    }, headers: @headers
    assert_response :success
    @response_record.reload
    assert @response_record.is_submitted
  end
end