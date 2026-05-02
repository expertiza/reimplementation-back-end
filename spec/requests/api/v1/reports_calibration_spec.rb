# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Reports calibration', type: :request do
  let!(:super_admin_role) { Role.create!(name: 'Super Administrator') }
  let!(:admin_role) { Role.create!(name: 'Administrator') }
  let!(:instructor_role) { Role.create!(name: 'Instructor') }
  let!(:student_role) { Role.create!(name: 'Student') }
  let(:institution) { create(:institution) }
  let(:instructor) { create_user(role: instructor_role, name: 'calibration_instructor') }
  let(:student_user) { create_user(role: student_role, name: 'calibration_student') }
  let(:assignment) { Assignment.create!(name: 'Calibration Assignment', instructor: instructor) }
  let(:questionnaire) { create_questionnaire }
  let(:code_quality) { create_item('Code quality', 1) }
  let(:documentation) { create_item('Documentation', 2) }
  let(:reviewee_team) { create(:assignment_team, assignment: assignment) }
  let(:instructor_participant) { create(:assignment_participant, assignment: assignment, user: instructor) }
  let(:student_participant) { create(:assignment_participant, assignment: assignment, user: student_user) }
  let(:instructor_map) do
    create(
      :review_response_map,
      :for_calibration,
      assignment: assignment,
      reviewer: instructor_participant,
      reviewee: reviewee_team
    )
  end
  let(:student_map) do
    create(
      :review_response_map,
      :for_calibration,
      assignment: assignment,
      reviewer: student_participant,
      reviewee: reviewee_team
    )
  end
  let(:instructor_headers) { auth_headers_for(instructor) }

  before do
    AssignmentQuestionnaire.create!(
      assignment: assignment,
      questionnaire: questionnaire,
      used_in_round: 1
    )
    code_quality
    documentation
  end

  # ---------------------------------------------------------------------------
  # Calibration participant management (add / list / remove)
  # ---------------------------------------------------------------------------
  describe 'POST /assignments/:assignment_id/review_mappings/calibration_participants' do
    let(:submitter_user) do
      User.create!(name: 'unctlt1', full_name: 'UNC TLT 1',
                   email: 'unctlt1@example.com', password: 'password',
                   role: student_role, institution: institution)
    end
    let(:participants_path) { "/assignments/#{assignment.id}/review_mappings/calibration_participants" }

    it 'atomically creates participant, team, and for_calibration map and returns 201' do
      submitter_user
      expect {
        post participants_path, params: { username: 'unctlt1' }, headers: instructor_headers
      }.to change { AssignmentParticipant.where(parent_id: assignment.id, user_id: submitter_user.id).count }.by(1)
        .and change { AssignmentTeam.where(parent_id: assignment.id).count }.by(1)
        .and change { ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count }.by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json).to include('username' => 'unctlt1', 'instructor_review_status' => 'not_started')
    end

    it 'returns 404 when the username does not exist' do
      post participants_path, params: { username: 'nobody' }, headers: instructor_headers
      expect(response).to have_http_status(:not_found)
    end

    it 'is idempotent — re-adding the same username does not create duplicate maps or teams' do
      submitter_user
      post participants_path, params: { username: 'unctlt1' }, headers: instructor_headers
      expect(response).to have_http_status(:created)

      maps_before  = ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count
      teams_before = AssignmentTeam.where(parent_id: assignment.id).count

      post participants_path, params: { username: 'unctlt1' }, headers: instructor_headers

      expect(response).to have_http_status(:created)
      expect(ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count).to eq(maps_before)
      expect(AssignmentTeam.where(parent_id: assignment.id).count).to eq(teams_before)
    end
  end

  describe 'GET /assignments/:assignment_id/reports/calibration/:map_id' do
    it 'returns report JSON for a calibration map' do
      create_response(
        map: instructor_map,
        submitted: true,
        scores: {
          code_quality => { answer: 4, comments: 'Clear implementation' },
          documentation => { answer: 5, comments: 'Complete docs' }
        }
      )
      create_response(
        map: student_map,
        submitted: true,
        scores: {
          code_quality => { answer: 3, comments: 'Mostly clear' },
          documentation => { answer: 5, comments: 'Strong docs' }
        }
      )
      SubmissionRecord.create!(
        record_type: 'file',
        content: 'submission/report.pdf',
        operation: 'Submit File',
        team_id: reviewee_team.id,
        user: instructor.name,
        assignment_id: assignment.id
      )
      reviewee_team.update!(submitted_hyperlinks: YAML.dump(['https://example.com/submission']))

      get calibration_report_path(instructor_map), headers: instructor_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['map_id']).to eq(instructor_map.id)
      expect(json['assignment_id']).to eq(assignment.id)
      expect(json['reviewee_id']).to eq(reviewee_team.id)
      expect(json['rubric_items'].map { |item| item['txt'] }).to eq(['Code quality', 'Documentation'])
      expect(json['instructor_response']['answers']).to include(
        hash_including('item_id' => code_quality.id, 'score' => 4, 'comments' => 'Clear implementation')
      )
      expect(json['student_responses'].length).to eq(1)
      expect(json['per_item_summary']).to include(
        hash_including(
          'item_id' => code_quality.id,
          'item_label' => 'Code quality',
          'instructor_score' => 4,
          'bucket_counts' => hash_including('3' => 1)
        )
      )
      expect(json['submitted_content']).to eq(
        'hyperlinks' => ['https://example.com/submission'],
        'files' => ['submission/report.pdf']
      )
    end

    it 'returns only the latest submitted student response for each calibration map' do
      create_response(
        map: instructor_map,
        submitted: true,
        scores: {
          code_quality => { answer: 4, comments: 'Instructor score' },
          documentation => { answer: 5, comments: 'Instructor docs' }
        }
      )
      create_response(
        map: student_map,
        submitted: true,
        updated_at: 2.days.ago,
        scores: {
          code_quality => { answer: 2, comments: 'Older response' },
          documentation => { answer: 3, comments: 'Older docs' }
        }
      )
      create_response(
        map: student_map,
        submitted: true,
        updated_at: 1.day.ago,
        scores: {
          code_quality => { answer: 5, comments: 'Latest response' },
          documentation => { answer: 4, comments: 'Latest docs' }
        }
      )

      get calibration_report_path(instructor_map), headers: instructor_headers

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['student_responses'].length).to eq(1)
      expect(json['student_responses'].first['answers']).to include(
        hash_including('item_id' => code_quality.id, 'score' => 5, 'comments' => 'Latest response'),
        hash_including('item_id' => documentation.id, 'score' => 4, 'comments' => 'Latest docs')
      )
      expect(json['per_item_summary']).to include(
        hash_including(
          'item_id' => code_quality.id,
          'bucket_counts' => hash_including('5' => 1, '2' => 0)
        )
      )
    end

    it 'returns 404 when the calibration map does not exist' do
      get "/assignments/#{assignment.id}/reports/calibration/0", headers: instructor_headers

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['error']).to eq('Calibration review map not found')
    end

    it 'returns 422 when the instructor response has not been submitted' do
      create_response(map: instructor_map, submitted: false, scores: { code_quality => { answer: 4 } })

      get calibration_report_path(instructor_map), headers: instructor_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('Submitted instructor calibration response not found')
    end

    it 'returns 403 for a student who is not teaching staff for the assignment' do
      create_response(map: instructor_map, submitted: true, scores: { code_quality => { answer: 4 } })

      get calibration_report_path(instructor_map), headers: auth_headers_for(student_user)

      expect(response).to have_http_status(:forbidden)
    end
  end

  def calibration_report_path(map)
    "/assignments/#{assignment.id}/reports/calibration/#{map.id}"
  end

  def auth_headers_for(user)
    { 'Authorization' => "Bearer #{JsonWebToken.encode(id: user.id)}" }
  end

  def create_user(role:, name:)
    User.create!(
      name: name,
      email: "#{name}@example.com",
      password: 'password',
      full_name: name.titleize,
      role: role,
      institution: institution
    )
  end

  def create_questionnaire
    Questionnaire.create!(
      name: 'Calibration Rubric',
      private: false,
      min_question_score: 0,
      max_question_score: 5,
      instructor: Instructor.find(instructor.id)
    )
  end

  def create_item(txt, seq)
    item = Item.create!(
      questionnaire: questionnaire,
      txt: txt,
      seq: seq,
      weight: 1,
      question_type: 'Scale',
      break_before: true
    )
    item.update!(seq: seq)
    item
  end

  def create_response(map:, submitted:, scores:, updated_at: Time.current)
    response = Response.create!(
      response_map: map,
      round: 1,
      version_num: 1,
      is_submitted: submitted,
      created_at: updated_at,
      updated_at: updated_at
    )

    scores.each do |item, score|
      Answer.create!(
        response: response,
        item: item,
        answer: score[:answer],
        comments: score[:comments]
      )
    end

    response
  end
end

# ---------------------------------------------------------------------------
# Service unit tests for Reports::CalibrationReport (bucket logic in isolation)
# ---------------------------------------------------------------------------
RSpec.describe Reports::CalibrationReport do
  let(:assignment)             { create(:assignment) }
  let(:reviewee_team)          { create(:assignment_team, assignment: assignment) }
  let(:instructor_participant) { create(:assignment_participant, assignment: assignment) }
  let(:instructor_map) do
    create(:review_response_map, :for_calibration,
           assignment: assignment, reviewer: instructor_participant, reviewee: reviewee_team)
  end
  let(:questionnaire) do
    Questionnaire.create!(
      name: "Calibration Rubric #{SecureRandom.hex(4)}",
      private: false, min_question_score: 0, max_question_score: 5,
      instructor: Instructor.find(instructor_participant.user_id)
    )
  end
  let!(:code_quality) { create(:item, questionnaire: questionnaire, txt: 'Code quality', seq: 1) }
  let!(:documentation) { create(:item, questionnaire: questionnaire, txt: 'Documentation', seq: 2) }

  before { AssignmentQuestionnaire.create!(assignment: assignment, questionnaire: questionnaire, used_in_round: 1) }

  def make_response(map:, submitted:, scores:, updated_at: Time.current)
    r = Response.create!(response_map: map, round: 1, version_num: 1,
                         is_submitted: submitted, created_at: updated_at, updated_at: updated_at)
    scores.each { |item, score| Answer.create!(response: r, item: item, answer: score[:answer], comments: score[:comments]) }
    r
  end

  it 'accumulates bucket counts from submitted student responses' do
    make_response(map: instructor_map, submitted: true,
                  scores: { code_quality => { answer: 4 }, documentation => { answer: 5 } })
    student_map = create(:review_response_map, :for_calibration, assignment: assignment,
                         reviewer: create(:assignment_participant, assignment: assignment), reviewee: reviewee_team)
    make_response(map: student_map, submitted: true,
                  scores: { code_quality => { answer: 3, comments: 'ok' }, documentation => { answer: 5 } })

    result = described_class.new(instructor_map).render
    cq = result[:per_item_summary].find { |s| s[:item_id] == code_quality.id }
    expect(cq[:instructor_score]).to eq(4)
    expect(cq[:bucket_counts]['3']).to eq(1)
    expect(cq[:bucket_counts]['4']).to eq(0)
  end

  it 'uses only the latest submitted response per student map' do
    make_response(map: instructor_map, submitted: true,
                  scores: { code_quality => { answer: 4 }, documentation => { answer: 5 } })
    student_map = create(:review_response_map, :for_calibration, assignment: assignment,
                         reviewer: create(:assignment_participant, assignment: assignment), reviewee: reviewee_team)
    make_response(map: student_map, submitted: true, updated_at: 2.days.ago,
                  scores: { code_quality => { answer: 1 }, documentation => { answer: 2 } })
    make_response(map: student_map, submitted: true, updated_at: 1.day.ago,
                  scores: { code_quality => { answer: 3 }, documentation => { answer: 2 } })
    make_response(map: student_map, submitted: false, updated_at: 1.hour.ago,
                  scores: { code_quality => { answer: 5 }, documentation => { answer: 5 } })

    result = described_class.new(instructor_map).render
    cq = result[:per_item_summary].find { |s| s[:item_id] == code_quality.id }
    expect(cq[:bucket_counts]['3']).to eq(1)
    expect(cq[:bucket_counts]['1']).to eq(0)
    expect(cq[:bucket_counts]['5']).to eq(0)
  end

  it 'raises InstructorResponseMissing when the instructor has not submitted' do
    expect { described_class.new(instructor_map).render }
      .to raise_error(Reports::CalibrationReport::InstructorResponseMissing)
  end
end
