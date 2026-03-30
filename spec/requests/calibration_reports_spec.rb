# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'CalibrationReports', type: :request do
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
      name: 'rep_instructor1',
      password: 'password',
      role_id: @roles[:instructor].id,
      full_name: 'Rep Instructor',
      email: 'rep_instructor1@example.com',
      institution: @institution
    )
  end

  let(:student_cal) do
    User.create!(
      name: 'rep_student_cal',
      password: 'password',
      role_id: @roles[:student].id,
      full_name: 'Calibration Author',
      email: 'rep_student_cal@example.com',
      institution: @institution
    )
  end

  let(:student_reviewer) do
    User.create!(
      name: 'rep_student_rev',
      password: 'password',
      role_id: @roles[:student].id,
      full_name: 'Student Reviewer',
      email: 'rep_student_rev@example.com',
      institution: @institution
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: 'Rep A1',
      instructor_id: instructor.id,
      directory_path: 'rep_a1',
      rounds_of_reviews: 1,
      max_team_size: 3
    )
  end

  let(:questionnaire) do
    Questionnaire.create!(name: 'Rep Q', min_question_score: 1, max_question_score: 5)
  end

  let!(:item) do
    Item.create!(
      questionnaire: questionnaire,
      txt: 'Criterion',
      weight: 1,
      seq: 1,
      question_type: 'scale',
      break_before: true
    )
  end

  before do
    AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire, used_in_round: 1)
  end

  it 'returns report JSON for instructor calibration map (200)' do
    headers = auth_headers_for(instructor)

    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student_cal.name },
         headers: headers
    expect(response).to have_http_status(:created)
    map_id = JSON.parse(response.body).dig('response_map', 'id')

    inst_part = AssignmentParticipant.find_by!(parent_id: assignment.id, user_id: instructor.id)
    cal_part = AssignmentParticipant.find_by!(parent_id: assignment.id, user_id: student_cal.id)
    rev_part = AssignmentParticipant.create!(
      parent_id: assignment.id,
      user_id: student_reviewer.id,
      handle: student_reviewer.name
    )

    instructor_map = ResponseMap.find(map_id)
    Response.create!(map_id: instructor_map.id, is_submitted: true, additional_comment: 'gold')
    Answer.create!(response_id: Response.last.id, item_id: item.id, answer: 4, comments: 'inst')

    student_map = ResponseMap.create!(
      reviewed_object_id: assignment.id,
      reviewer_id: rev_part.id,
      reviewee_id: cal_part.id,
      for_calibration: true
    )
    Response.create!(map_id: student_map.id, is_submitted: true, additional_comment: 'st')
    Answer.create!(response_id: Response.last.id, item_id: item.id, answer: 3, comments: 'near')

    get "/assignments/#{assignment.id}/calibration_reports/#{map_id}", headers: headers
    expect(response).to have_http_status(:ok)
    body = JSON.parse(response.body)

    expect(body['response_map_id']).to eq(map_id)
    expect(body['rubric']).to be_an(Array)
    expect(body['instructor_response']['answers'].first['answer']).to eq(4)
    expect(body['student_responses'].size).to eq(1)
    summary = body['per_item_summary'].find { |s| s['item_id'] == item.id }
    expect(summary['agree']).to eq(0)
    expect(summary['near']).to eq(1)
    expect(summary['disagree']).to eq(0)
  end

  it 'forbids students (403)' do
    post "/assignments/#{assignment.id}/calibration_response_maps",
         params: { username: student_cal.name },
         headers: auth_headers_for(instructor)
    map_id = JSON.parse(response.body).dig('response_map', 'id')

    get "/assignments/#{assignment.id}/calibration_reports/#{map_id}", headers: auth_headers_for(student_cal)
    expect(response).to have_http_status(:forbidden)
  end
end
