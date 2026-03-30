require 'test_helper'

class ResponsesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @student      = users(:student_user)
    @headers      = { 'Authorization' => "Bearer #{@student.generate_jwt}" }
    @response_map = response_maps(:student_response_map)
    @response_record = responses(:response_one)
  end

  test 'should show response' do
    get response_url(@response_record), headers: @headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal @response_record.id, json['response_id']
  end

  test 'should create response' do
    post responses_url, params: {
      response_map_id: @response_map.id,
      round: 1,
      content: '{}'
    }, headers: @headers
    assert_response :created
    json = JSON.parse(response.body)
    assert json['response_id'].present?
    assert_equal @response_map.id, json['map_id']
  end

  test 'should update response' do
    patch response_url(@response_record), params: {
      is_submitted: true
    }, headers: @headers
    assert_response :success
    @response_record.reload
    assert @response_record.is_submitted
  end

  test 'create returns forbidden when response_map_id does not belong to current user' do
    other_map = response_maps(:other_user_response_map)
    post responses_url, params: {
      response_map_id: other_map.id,
      round: 1
    }, headers: @headers
    assert_response :forbidden
  end
  test 'create returns forbidden when no TeamsParticipant exists for reviewer' do
    TeamsParticipant.stub(:find_by, nil) do
      post responses_url, params: {
        response_map_id: @response_map.id,
        round: 1
      }, headers: @headers
    end
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal 'TeamsParticipant not found for reviewer', json['error']
  end

  test 'create returns forbidden when map is not in task queue' do
    fake_queue = Minitest::Mock.new
    fake_queue.expect(:map_in_queue?, false, [@response_map.id])

    TaskOrdering::TaskQueue.stub(:new, fake_queue) do
      post responses_url, params: {
        response_map_id: @response_map.id,
        round: 1
      }, headers: @headers
    end
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal 'Response map is not a respondable task for this participant', json['error']
  end

  test 'create returns forbidden when prior tasks are not complete' do
    fake_queue = Minitest::Mock.new
    fake_queue.expect(:map_in_queue?, true, [@response_map.id])
    fake_queue.expect(:prior_tasks_complete_for?, false, [@response_map.id])

    TaskOrdering::TaskQueue.stub(:new, fake_queue) do
      post responses_url, params: {
        response_map_id: @response_map.id,
        round: 1
      }, headers: @headers
    end
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal 'Complete previous task first', json['error']
  end

  test 'update sets additional_comment from content param' do
    patch response_url(@response_record), params: {
      content: 'Great work'
    }, headers: @headers
    assert_response :success
    @response_record.reload
    assert_equal 'Great work', @response_record.additional_comment
  end

  test 'update returns forbidden when prior tasks are not complete' do
    fake_queue = Minitest::Mock.new
    fake_queue.expect(:map_in_queue?, true, [@response_map.id])
    fake_queue.expect(:prior_tasks_complete_for?, false, [@response_map.id])

    TaskOrdering::TaskQueue.stub(:new, fake_queue) do
      patch response_url(@response_record), params: { is_submitted: true }, headers: @headers
    end
    assert_response :forbidden
    json = JSON.parse(response.body)
    assert_equal 'Complete previous task first', json['error']
  end

  test 'update returns unprocessable_entity when update fails' do
    @response_record.define_singleton_method(:update) { |_| false }
    @response_record.define_singleton_method(:errors) do
      OpenStruct.new(full_messages: ['is_submitted is invalid'])
    end

    Response.stub(:find, @response_record) do
      patch response_url(@response_record), params: { is_submitted: true }, headers: @headers
    end
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json['errors'].present?
  end
end