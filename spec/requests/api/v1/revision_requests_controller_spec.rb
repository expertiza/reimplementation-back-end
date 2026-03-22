# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'RevisionRequests API', type: :request do
  include RolesHelper

  let!(:roles) { create_roles_hierarchy }
  let!(:institution) { Institution.create!(name: 'NC State') }

  let!(:instructor) do
    User.create!(
      name: 'instructor1',
      email: 'instructor1@example.com',
      password: 'password',
      full_name: 'Instructor One',
      institution: institution,
      role: roles[:instructor]
    )
  end

  let!(:other_instructor) do
    User.create!(
      name: 'instructor2',
      email: 'instructor2@example.com',
      password: 'password',
      full_name: 'Instructor Two',
      institution: institution,
      role: roles[:instructor]
    )
  end

  let!(:course) do
    Course.create!(
      name: 'CSC 517',
      directory_path: 'csc517',
      institution: institution,
      instructor: instructor
    )
  end

  let!(:assignment) do
    Assignment.create!(
      name: 'Assignment One',
      instructor: instructor,
      course: course,
      directory_path: 'assignment_one'
    )
  end

  let!(:student) do
    User.create!(
      name: 'student1',
      email: 'student1@example.com',
      password: 'password',
      full_name: 'Student One',
      institution: institution,
      role: roles[:student]
    )
  end

  let!(:other_student) do
    User.create!(
      name: 'student2',
      email: 'student2@example.com',
      password: 'password',
      full_name: 'Student Two',
      institution: institution,
      role: roles[:student]
    )
  end

  let!(:third_student) do
    User.create!(
      name: 'student3',
      email: 'student3@example.com',
      password: 'password',
      full_name: 'Student Three',
      institution: institution,
      role: roles[:student]
    )
  end

  let!(:team_one) { AssignmentTeam.create!(name: 'Team Alpha', parent_id: assignment.id) }
  let!(:team_two) { AssignmentTeam.create!(name: 'Team Beta', parent_id: assignment.id) }

  let!(:participant_one) do
    AssignmentParticipant.create!(
      user: student,
      assignment: assignment,
      handle: student.name,
      current_stage: 'In progress'
    )
  end

  let!(:participant_two) do
    AssignmentParticipant.create!(
      user: other_student,
      assignment: assignment,
      handle: other_student.name,
      current_stage: 'Submitted'
    )
  end

  let!(:team_membership_one) do
    TeamsParticipant.create!(team: team_one, participant: participant_one, user: student)
  end

  let!(:team_membership_two) do
    TeamsParticipant.create!(team: team_two, participant: participant_two, user: other_student)
  end

  let!(:declined_request) do
    RevisionRequest.create!(
      participant: participant_two,
      team: team_two,
      assignment: assignment,
      comments: 'Please allow another attempt.',
      status: RevisionRequest::DECLINED,
      response_comment: 'Use the existing submission for grading.'
    )
  end

  let!(:pending_request) do
    RevisionRequest.create!(
      participant: participant_one,
      team: team_one,
      assignment: assignment,
      comments: 'Please reopen the submission.'
    )
  end

  let(:instructor_headers) { auth_headers_for(instructor) }
  let(:other_instructor_headers) { auth_headers_for(other_instructor) }
  let(:student_headers) { auth_headers_for(student) }
  let(:other_student_headers) { auth_headers_for(other_student) }
  let(:third_student_headers) { auth_headers_for(third_student) }

  describe 'GET /revision_requests' do
    it 'returns assignment revision requests for the assignment instructor' do
      get '/revision_requests', params: { assignment_id: assignment.id }, headers: instructor_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body.map { |item| item['id'] }).to eq([pending_request.id, declined_request.id])
      expect(body.first).to include(
        'participant_id' => participant_one.id,
        'team_id' => team_one.id,
        'assignment_id' => assignment.id,
        'status' => 'PENDING',
        'comments' => 'Please reopen the submission.'
      )
    end

    it 'filters revision requests by status' do
      get '/revision_requests',
          params: { assignment_id: assignment.id, status: RevisionRequest::DECLINED },
          headers: instructor_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)

      expect(body.size).to eq(1)
      expect(body.first).to include(
        'id' => declined_request.id,
        'status' => 'DECLINED',
        'response_comment' => 'Use the existing submission for grading.'
      )
    end

    it 'returns not found for an invalid assignment id' do
      get '/revision_requests', params: { assignment_id: 999_999 }, headers: instructor_headers

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq('error' => 'Assignment not found')
    end

    it 'returns unprocessable entity for an invalid status filter' do
      get '/revision_requests',
          params: { assignment_id: assignment.id, status: 'INVALID' },
          headers: instructor_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'Status must be PENDING, APPROVED, or DECLINED')
    end

    it 'returns forbidden for a different instructor' do
      get '/revision_requests', params: { assignment_id: assignment.id }, headers: other_instructor_headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns forbidden for a student' do
      get '/revision_requests', params: { assignment_id: assignment.id }, headers: student_headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns unauthorized without a valid token' do
      get '/revision_requests', params: { assignment_id: assignment.id }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
    end
  end

  describe 'GET /revision_requests/:id' do
    it 'returns the revision request for the owning student' do
      get "/revision_requests/#{pending_request.id}", headers: student_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        'id' => pending_request.id,
        'participant_id' => participant_one.id,
        'status' => 'PENDING'
      )
    end

    it 'returns the revision request for the assignment instructor' do
      get "/revision_requests/#{pending_request.id}", headers: instructor_headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include(
        'id' => pending_request.id,
        'comments' => 'Please reopen the submission.'
      )
    end

    it 'returns forbidden for another student' do
      get "/revision_requests/#{pending_request.id}", headers: third_student_headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for an invalid revision request id' do
      get '/revision_requests/999999', headers: instructor_headers

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq('error' => 'Revision request not found')
    end

    it 'returns unauthorized without a valid token' do
      get "/revision_requests/#{pending_request.id}"

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
    end
  end

  describe 'PATCH /revision_requests/:id' do
    it 'allows the assignment instructor to approve a pending revision request' do
      patch "/revision_requests/#{pending_request.id}",
            params: { revision_request: { status: RevisionRequest::APPROVED, response_comment: 'Approved for one more submission.' } },
            headers: instructor_headers

      expect(response).to have_http_status(:ok)
      expect(pending_request.reload).to have_attributes(
        status: RevisionRequest::APPROVED,
        response_comment: 'Approved for one more submission.'
      )
      expect(JSON.parse(response.body)).to include(
        'id' => pending_request.id,
        'status' => 'APPROVED',
        'response_comment' => 'Approved for one more submission.'
      )
    end

    it 'allows the assignment instructor to decline a pending revision request' do
      patch "/revision_requests/#{pending_request.id}",
            params: { revision_request: { status: RevisionRequest::DECLINED, response_comment: 'The current submission will stand.' } },
            headers: instructor_headers

      expect(response).to have_http_status(:ok)
      expect(pending_request.reload).to have_attributes(
        status: RevisionRequest::DECLINED,
        response_comment: 'The current submission will stand.'
      )
    end

    it 'rejects an invalid resolution status' do
      patch "/revision_requests/#{pending_request.id}",
            params: { revision_request: { status: RevisionRequest::PENDING } },
            headers: instructor_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'Status must be APPROVED or DECLINED')
    end

    it 'rejects updates after a request has already been processed' do
      patch "/revision_requests/#{declined_request.id}",
            params: { revision_request: { status: RevisionRequest::APPROVED, response_comment: 'Changing the decision.' } },
            headers: instructor_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq('error' => 'This revision request has already been processed')
    end

    it 'returns forbidden for a student' do
      patch "/revision_requests/#{pending_request.id}",
            params: { revision_request: { status: RevisionRequest::APPROVED } },
            headers: student_headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns forbidden for a different instructor' do
      patch "/revision_requests/#{pending_request.id}",
            params: { revision_request: { status: RevisionRequest::APPROVED } },
            headers: other_instructor_headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for an invalid revision request id' do
      patch '/revision_requests/999999',
            params: { revision_request: { status: RevisionRequest::APPROVED } },
            headers: instructor_headers

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq('error' => 'Revision request not found')
    end

    it 'returns unauthorized without a valid token' do
      patch "/revision_requests/#{pending_request.id}",
            params: { revision_request: { status: RevisionRequest::APPROVED } }

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq('error' => 'Not Authorized')
    end
  end

  def auth_headers_for(user)
    token = JsonWebToken.encode(id: user.id)
    { 'Authorization' => "Bearer #{token}" }
  end
end
