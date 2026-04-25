# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

# Behaviour-driven specs for the "Add calibration participant" feature on the
# assignment Calibration tab. Scenarios are written from the perspective of the
# instructor using the UI and exercise the public HTTP contract end-to-end:
#
#   * GET    /assignments/:id/review_mappings/calibration_participants
#   * POST   /assignments/:id/review_mappings/calibration_participants
#   * DELETE /assignments/:id/review_mappings/calibration_participants/:participant_id
#
# Each `it` block reads as a scenario with explicit Given / When / Then phases
# so the spec doubles as living documentation of the feature's behaviour.
RSpec.describe 'Feature: Designating calibration submitters', type: :request do
  # ---------------------------------------------------------------------------
  # Background fixtures (the "Given" that every scenario shares)
  # ---------------------------------------------------------------------------
  let!(:super_admin_role) { Role.find_or_create_by!(name: 'Super Administrator') }
  let!(:admin_role)       { Role.find_or_create_by!(name: 'Administrator',      parent: super_admin_role) }
  let!(:instructor_role)  { Role.find_or_create_by!(name: 'Instructor',         parent: admin_role) }
  let!(:ta_role)          { Role.find_or_create_by!(name: 'Teaching Assistant', parent: instructor_role) }
  let!(:student_role)     { Role.find_or_create_by!(name: 'Student',            parent: ta_role) }

  let(:institution) { Institution.create!(name: 'NC State') }

  let(:instructor_user) do
    User.create!(
      name: 'calib_instr', full_name: 'Calibration Instructor',
      email: 'calib_instr@example.com', password: 'password',
      role: instructor_role, institution: institution
    )
  end

  let(:other_student) do
    User.create!(
      name: 'calib_student_user', full_name: 'Calibration Student',
      email: 'calib_student_user@example.com', password: 'password',
      role: student_role, institution: institution
    )
  end

  # The phantom calibration submitter the instructor will type into the form.
  let(:phantom_user) do
    User.create!(
      name: 'unctlt1', full_name: 'UNC TLT 1',
      email: 'unctlt1@example.com', password: 'password',
      role: student_role, institution: institution
    )
  end

  let(:assignment) do
    Assignment.create!(name: 'Calibration Assignment', instructor: instructor_user, max_team_size: 1)
  end

  let(:base_path)        { "/assignments/#{assignment.id}/review_mappings/calibration_participants" }
  let(:as_instructor)    { { 'Authorization' => "Bearer #{JsonWebToken.encode(id: instructor_user.id)}" } }
  let(:as_student)       { { 'Authorization' => "Bearer #{JsonWebToken.encode(id: other_student.id)}" } }

  # Convenience helper used in many "When" steps.
  def add_calibration_participant(username, headers: as_instructor)
    post base_path, params: { username: username }, headers: headers
  end

  # ---------------------------------------------------------------------------
  # Scenario group: adding a participant
  # ---------------------------------------------------------------------------
  describe 'Scenario: an instructor adds a new calibration submitter by username' do
    it 'creates the participant, the team, and the for_calibration map atomically' do
      # Given the phantom user exists
      phantom_user

      # When the instructor submits "unctlt1" through the calibration tab
      expect {
        add_calibration_participant('unctlt1')
      }.to change { AssignmentParticipant.where(parent_id: assignment.id, user_id: phantom_user.id).count }.by(1)
        .and change { AssignmentTeam.where(parent_id: assignment.id).count }.by(1)
        .and change { ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count }.by(1)

      # Then the API responds 201 with the new row
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json).to include(
        'username'   => 'unctlt1',
        'full_name'  => 'UNC TLT 1'
      )
      expect(json['team_id']).to be_present
      expect(json['instructor_review_map_id']).to be_present
      expect(json['instructor_review_status']).to eq('not_started')

      # And the calibration map is wired to the instructor as reviewer
      map = ReviewResponseMap.find(json['instructor_review_map_id'])
      expect(map.for_calibration).to be true
      expect(map.reviewed_object_id).to eq(assignment.id)

      instructor_participant = AssignmentParticipant.find_by(parent_id: assignment.id, user_id: instructor_user.id)
      expect(map.reviewer_id).to eq(instructor_participant.id)
      expect(map.reviewee_id).to eq(json['team_id'])
    end

    it 'accepts an email address in place of a username' do
      # Given the phantom user exists
      phantom_user

      # When the instructor types the user's email instead of their handle
      add_calibration_participant('unctlt1@example.com')

      # Then the user is still resolved and added
      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['username']).to eq('unctlt1')
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario group: invalid input
  # ---------------------------------------------------------------------------
  describe 'Scenario: invalid input from the instructor' do
    it 'rejects a request with a missing username with HTTP 400' do
      # When the instructor submits an empty form
      post base_path, params: {}, headers: as_instructor

      # Then the request is rejected as bad input
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)['error']).to match(/username is required/i)
    end

    it 'rejects a blank/whitespace username with HTTP 400' do
      add_calibration_participant('   ')
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns HTTP 404 when no user matches the username or email' do
      # When the instructor types a name that does not exist
      add_calibration_participant('nope')

      # Then nothing is created and a 404 is returned
      expect(response).to have_http_status(:not_found)
      expect(ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true)).to be_empty
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario group: idempotence and re-adding
  # ---------------------------------------------------------------------------
  describe 'Scenario: re-adding the same submitter' do
    it 'is idempotent and does not create duplicate maps or teams' do
      # Given the participant has already been added once
      phantom_user
      add_calibration_participant('unctlt1')
      expect(response).to have_http_status(:created)

      maps_before  = ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count
      teams_before = AssignmentTeam.where(parent_id: assignment.id).count

      # When the instructor adds the same person again
      add_calibration_participant('unctlt1')

      # Then no extra rows are created and the response is still successful
      expect(response).to have_http_status(:created)
      expect(ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count).to eq(maps_before)
      expect(AssignmentTeam.where(parent_id: assignment.id).count).to eq(teams_before)
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario group: authorization
  # ---------------------------------------------------------------------------
  describe 'Scenario: only teaching staff may add calibration submitters' do
    it 'rejects students with HTTP 403 and creates nothing' do
      phantom_user

      expect {
        add_calibration_participant('unctlt1', headers: as_student)
      }.not_to change { ReviewResponseMap.count }

      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects unauthenticated requests with HTTP 401' do
      phantom_user

      post base_path, params: { username: 'unctlt1' }
      expect([401, 403]).to include(response.status), "expected 401/403 for unauthenticated request, got #{response.status}"
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario group: listing the calibration submitters
  # ---------------------------------------------------------------------------
  describe 'Scenario: instructor views the list of calibration submitters' do
    it 'returns each submitter with their team, hyperlinks, and submitted files' do
      # Given a calibration submitter already exists for this assignment
      phantom_user
      add_calibration_participant('unctlt1')
      added_row = JSON.parse(response.body)

      # And that submitter has uploaded a file and a hyperlink to their team
      team = AssignmentTeam.find(added_row['team_id'])
      SubmissionRecord.create!(
        record_type: 'file', content: 'submission/report.pdf', operation: 'Submit File',
        team_id: team.id, user: phantom_user.name, assignment_id: assignment.id
      )
      team.update!(submitted_hyperlinks: YAML.dump(['https://example.com/submission']))

      # When the instructor opens the calibration tab
      get base_path, headers: as_instructor

      # Then the response contains exactly one calibration submitter row
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['assignment_id']).to eq(assignment.id)
      expect(json['calibration_participants'].length).to eq(1)

      # And that row exposes the submitter's hyperlinks and files
      entry = json['calibration_participants'].first
      expect(entry['username']).to eq('unctlt1')
      expect(entry['instructor_review_map_id']).to eq(added_row['instructor_review_map_id'])
      expect(entry['submissions']['hyperlinks']).to eq(['https://example.com/submission'])
      expect(entry['submissions']['files'].first).to include(
        'name'         => 'report.pdf',
        'path'         => 'submission/report.pdf',
        'submitted_by' => phantom_user.name
      )
    end

    it 'returns an empty list when no calibration submitters have been added' do
      # When the instructor opens the calibration tab on a fresh assignment
      get base_path, headers: as_instructor

      # Then the list is empty (but the response is well-formed)
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['assignment_id']).to eq(assignment.id)
      expect(json['calibration_participants']).to eq([])
    end

    it 'reflects the instructor review status (not_started -> in_progress -> submitted)' do
      # Given a calibration submitter exists
      phantom_user
      add_calibration_participant('unctlt1')
      map_id = JSON.parse(response.body)['instructor_review_map_id']
      map    = ReviewResponseMap.find(map_id)

      # Then before any review work the status is :not_started
      get base_path, headers: as_instructor
      expect(JSON.parse(response.body)['calibration_participants'].first['instructor_review_status']).to eq('not_started')

      # When the instructor saves a draft response
      Response.create!(response_map: map, round: 1, version_num: 1, is_submitted: false)
      get base_path, headers: as_instructor
      expect(JSON.parse(response.body)['calibration_participants'].first['instructor_review_status']).to eq('in_progress')

      # When the instructor submits the response
      Response.where(map_id: map.id).update_all(is_submitted: true)
      get base_path, headers: as_instructor
      expect(JSON.parse(response.body)['calibration_participants'].first['instructor_review_status']).to eq('submitted')
    end
  end

  # ---------------------------------------------------------------------------
  # Scenario group: removing a submitter
  # ---------------------------------------------------------------------------
  describe 'Scenario: instructor removes a calibration submitter' do
    it 'destroys the for_calibration maps for that submitter' do
      # Given a calibration submitter has been added
      phantom_user
      add_calibration_participant('unctlt1')
      participant_id = JSON.parse(response.body)['participant_id']

      # When the instructor removes them
      expect {
        delete "#{base_path}/#{participant_id}", headers: as_instructor
      }.to change { ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count }.to(0)

      # Then the API responds 200 OK
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to match(/removed/i)
    end

    it 'returns HTTP 404 for a participant id that does not belong to this assignment' do
      delete "#{base_path}/999999", headers: as_instructor
      expect(response).to have_http_status(:not_found)
    end

    it 'rejects students with HTTP 403' do
      phantom_user
      add_calibration_participant('unctlt1')
      participant_id = JSON.parse(response.body)['participant_id']

      expect {
        delete "#{base_path}/#{participant_id}", headers: as_student
      }.not_to change { ReviewResponseMap.where(reviewed_object_id: assignment.id, for_calibration: true).count }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
