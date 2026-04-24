# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Calibration participants API (on ReviewMappingsController)', type: :request do
  let!(:super_admin_role) { Role.find_or_create_by!(name: 'Super Administrator') }
  let!(:admin_role)       { Role.find_or_create_by!(name: 'Administrator',      parent: super_admin_role) }
  let!(:instructor_role)  { Role.find_or_create_by!(name: 'Instructor',         parent: admin_role) }
  let!(:ta_role)          { Role.find_or_create_by!(name: 'Teaching Assistant', parent: instructor_role) }
  let!(:student_role)     { Role.find_or_create_by!(name: 'Student',            parent: ta_role) }

  let(:institution) { Institution.create!(name: 'NC State') }

  let(:instructor_user) do
    User.create!(
      name: 'calib_instr',
      full_name: 'Calibration Instructor',
      email: 'calib_instr@example.com',
      password: 'password',
      role: instructor_role,
      institution: institution
    )
  end

  let(:student_user) do
    User.create!(
      name: 'calib_student_user',
      full_name: 'Calibration Student',
      email: 'calib_student_user@example.com',
      password: 'password',
      role: student_role,
      institution: institution
    )
  end

  let(:phantom_user) do
    User.create!(
      name: 'unctlt1',
      full_name: 'UNC TLT 1',
      email: 'unctlt1@example.com',
      password: 'password',
      role: student_role,
      institution: institution
    )
  end

  let(:assignment) do
    Assignment.create!(name: 'Calibration Assignment', instructor: instructor_user, max_team_size: 1)
  end

  let(:base_path)    { "/assignments/#{assignment.id}/review_mappings/calibration_participants" }
  let(:instr_header) { { 'Authorization' => "Bearer #{JsonWebToken.encode(id: instructor_user.id)}" } }
  let(:student_hdr)  { { 'Authorization' => "Bearer #{JsonWebToken.encode(id: student_user.id)}" } }

  describe 'POST .../calibration_participants' do
    it 'adds a calibration participant, creates a team, and creates a for_calibration map for the instructor' do
      phantom_user

      expect {
        post base_path, params: { username: 'unctlt1' }, headers: instr_header
      }.to change { AssignmentParticipant.where(parent_id: assignment.id, user_id: phantom_user.id).count }.by(1)
        .and change { AssignmentTeam.where(parent_id: assignment.id).count }.by(1)
        .and change { ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count }.by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['username']).to eq('unctlt1')
      expect(json['team_id']).to be_present
      expect(json['instructor_review_map_id']).to be_present

      map = ReviewResponseMap.find(json['instructor_review_map_id'])
      expect(map.for_calibration).to be true
      expect(map.reviewed_object_id).to eq(assignment.id)

      instructor_participant = AssignmentParticipant.find_by(parent_id: assignment.id, user_id: instructor_user.id)
      expect(map.reviewer_id).to eq(instructor_participant.id)
    end

    it 'returns 400 when username is missing' do
      post base_path, params: {}, headers: instr_header
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 404 when the user cannot be found' do
      post base_path, params: { username: 'nope' }, headers: instr_header
      expect(response).to have_http_status(:not_found)
    end

    it 'is idempotent for the same username' do
      phantom_user

      post base_path, params: { username: 'unctlt1' }, headers: instr_header
      expect(response).to have_http_status(:created)

      expect {
        post base_path, params: { username: 'unctlt1' }, headers: instr_header
      }.not_to change { ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count }
    end

    it 'returns 403 for non-teaching-staff' do
      phantom_user
      post base_path, params: { username: 'unctlt1' }, headers: student_hdr
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET .../calibration_participants' do
    it 'lists calibration submitters with their submissions' do
      phantom_user
      post base_path, params: { username: 'unctlt1' }, headers: instr_header
      expect(response).to have_http_status(:created)
      row = JSON.parse(response.body)

      team = AssignmentTeam.find(row['team_id'])
      SubmissionRecord.create!(
        record_type: 'file',
        content: 'submission/report.pdf',
        operation: 'Submit File',
        team_id: team.id,
        user: phantom_user.name,
        assignment_id: assignment.id
      )
      team.update!(submitted_hyperlinks: YAML.dump(['https://example.com/submission']))

      get base_path, headers: instr_header
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json['assignment_id']).to eq(assignment.id)
      expect(json['calibration_participants'].length).to eq(1)

      entry = json['calibration_participants'].first
      expect(entry['username']).to eq('unctlt1')
      expect(entry['submissions']['hyperlinks']).to eq(['https://example.com/submission'])
      expect(entry['submissions']['files'].first).to include(
        'name' => 'report.pdf',
        'path' => 'submission/report.pdf',
        'submitted_by' => phantom_user.name
      )
      expect(entry['instructor_review_map_id']).to eq(row['instructor_review_map_id'])
    end
  end

  describe 'DELETE .../calibration_participants/:participant_id' do
    it 'removes the for_calibration maps for the submitter' do
      phantom_user
      post base_path, params: { username: 'unctlt1' }, headers: instr_header
      participant_id = JSON.parse(response.body)['participant_id']

      expect {
        delete "#{base_path}/#{participant_id}", headers: instr_header
      }.to change { ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count }.to(0)

      expect(response).to have_http_status(:ok)
    end
  end
end
