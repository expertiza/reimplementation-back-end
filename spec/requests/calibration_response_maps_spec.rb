# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'CalibrationResponseMaps', type: :request do
  include RolesHelper

  before(:all) do
    @roles = create_roles_hierarchy
    @institution = Institution.first || Institution.create!(name: 'Test Institution')
  end

  def auth_headers_for(user)
    token = JsonWebToken.encode({ id: user.id })
    { 'Authorization' => "Bearer #{token}" }
  end

  let(:instructor) do
    User.create!(
      name: 'instructor1',
      password: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Instructor One',
      email: 'instructor1@example.com',
      institution: @institution
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: 'A1',
      instructor_id: instructor.id,
      directory_path: 'a1_dir',
      rounds_of_reviews: 1,
      max_team_size: 3
    )
  end

  let(:questionnaire) do
    Questionnaire.create!(name: 'Cal Q', min_question_score: 0, max_question_score: 5)
  end

  let!(:rubric_item_one) do
    Item.create!(
      questionnaire: questionnaire,
      txt: 'Q1',
      weight: 1,
      seq: 1,
      question_type: 'scale',
      break_before: true
    )
  end

  let!(:rubric_item_two) do
    Item.create!(
      questionnaire: questionnaire,
      txt: 'Q2',
      weight: 1,
      seq: 2,
      question_type: 'scale',
      break_before: true
    )
  end

  before do
    AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire, used_in_round: 1)
  end

  let(:student) do
    User.create!(
      name: 'student1',
      password: 'password',
      role_id: @roles[:student].id,
      full_name: 'Student One',
      email: 'student1@example.com',
      institution: @institution
    )
  end

  it 'creates (or reuses) participant and creates a for_calibration response map (201)' do
    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: auth_headers_for(instructor)

    expect(response).to have_http_status(:created)
    body = JSON.parse(response.body)

    expect(body['participant']).to be_present
    expect(body['participant']['user']).to be_present
    expect(body['participant']['user']['name']).to eq(student.name)

    expect(body['response_map']).to be_present
    expect(body['response_map']['for_calibration']).to eq(true)
    expect(body['response_map']['reviewed_object_id']).to eq(assignment.id)

    # Some clients expect a team-like payload with hyperlinks always present.
    expect(body['team']).to be_present
    expect(body['team']['hyperlinks']).to eq([])
  end

  it 'is idempotent for participant and response_map' do
    headers = auth_headers_for(instructor)

    expect do
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers
    end.to change(AssignmentParticipant, :count).by(2) # student + instructor participant
                                                .and change(ResponseMap, :count).by(1)

    expect do
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers
    end.not_to change(AssignmentParticipant, :count)

    expect do
      post "/assignments/#{assignment.id}/calibration_response_maps",
           params: { username: student.name },
           headers: headers
    end.not_to change(ResponseMap, :count)
  end

  it 'returns 404 for unknown username' do
    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: 'does_not_exist' },
         headers: auth_headers_for(instructor)

    expect(response).to have_http_status(:not_found)
    body = JSON.parse(response.body)
    expect(body['error']).to match(/Unknown username/)
  end

  it 'forbids students (403)' do
    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: auth_headers_for(student)

    expect(response).to have_http_status(:forbidden)
  end

  it 'GET index creates instructor participant if missing (200, empty list)' do
    headers = auth_headers_for(instructor)
    expect(AssignmentParticipant.where(parent_id: assignment.id, user_id: instructor.id)).not_to exist

    get "/assignments/#{assignment.id}/calibration_response_maps", headers: headers
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq([])

    expect(AssignmentParticipant.find_by(parent_id: assignment.id, user_id: instructor.id)).to be_present
  end

  it 'lists calibration response maps for the instructor (200)' do
    headers = auth_headers_for(instructor)

    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: headers
    expect(response).to have_http_status(:created)

    get "/assignments/#{assignment.id}/calibration_response_maps", headers: headers
    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    expect(body).to be_an(Array)
    expect(body.length).to eq(1)
    expect(body.first['for_calibration']).to eq(true)
    expect(body.first.dig('reviewee', 'user', 'name')).to eq(student.name)
    expect(body.first['participant_name']).to eq(student.full_name)
    expect(body.first['submitted_content']).to be_a(Hash)
    expect(body.first['submitted_content']['hyperlinks']).to eq([])
    expect(body.first['review_status']).to eq('not_started')
  end

  it 'returns routing info for begin (200)' do
    headers = auth_headers_for(instructor)

    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: headers
    created = JSON.parse(response.body)
    map_id = created.dig('response_map', 'id')
    expect(map_id).to be_present

    post "/assignments/#{assignment.id}/calibration_response_maps/#{map_id}/begin", headers: headers
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['map_id']).to eq(map_id)
    expect(body['redirect_to']).to eq("/assignments/edit/#{assignment.id}/calibration/#{map_id}/review")
  end

  it 'saves instructor_response JSON with distinct scores per item and submits (200)' do
    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student.name },
         headers: auth_headers_for(instructor)
    expect(response).to have_http_status(:created)
    map_id = JSON.parse(response.body).dig('response_map', 'id')

    payload = {
      answers: [
        { item_id: rubric_item_one.id, answer: 4, comments: 'a' },
        { item_id: rubric_item_two.id, answer: 2, comments: 'b' }
      ],
      additional_comment: 'overall',
      is_submitted: true
    }

    post "/assignments/#{assignment.id}/calibration_response_maps/#{map_id}/instructor_response",
         params: payload.to_json,
         headers: auth_headers_for(instructor).merge('Content-Type' => 'application/json')

    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)
    expect(body['is_submitted']).to eq(true)
    by_item = body['answers'].to_h { |x| [x['item_id'], x] }
    expect(by_item[rubric_item_one.id]['answer']).to eq(4)
    expect(by_item[rubric_item_two.id]['answer']).to eq(2)
  end
end
