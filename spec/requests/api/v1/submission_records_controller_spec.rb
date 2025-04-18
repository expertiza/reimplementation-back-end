# frozen_string_literal: true
require 'rails_helper'
require 'swagger_helper'
require 'json_web_token'

# spec/requests/api/v1/submission_records_spec.rb

#INITIALIZE TESTING OBJECTS
RSpec.describe 'Submission Records API', type: :request do
  let(:valid_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode({ id: studenta.id })}" } }
  let(:invalid_headers) { { "Authorization" => "Bearer invalid_token" } }
  let(:unauthorized_headers) { { "Authorization" => "Bearer #{JsonWebToken.encode({ id: studentb.id })}" } }
  #call roles hierarchy to create sample roles
  before(:all) do
    @roles = create_roles_hierarchy
  end

  #OBJECTIVE: Create appropriate structures for student functionality testing.
  # Two different students will be created and one assignment associated with one of those students
  # The assignment will have a designated team and associated submission record

  let(:studenta) do
    User.create!(
      name: 'StudentA',
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student A",
      email: "studenta@example.com",
    )
  end

  let(:studentb) do
    User.create!(
      name: 'StudentB',
      password_digest: "password",
      role_id: @roles[:student].id,
      full_name: "Student B",
      email: "studentb@example.com",
      )
  end

  #instructor is created as an associate of the assignment
  let!(:instructor) do
    User.create!(
      name: "Instructor",
      password_digest: "password",
      role_id: @roles[:instructor].id,
      full_name: "Instructor Name",
      email: "instructor@example.com"
    )
  end
  let!(:assignment1) do
    Assignment.create!(
      name: 'Test Assignment',
      instructor_id: instructor.id
    )
  end
  let!(:team) do
    Team.create!(
      name: 'Team A',
      assignment: assignment1,
      users: [studenta], #only student a is on the team to test if student b can access
      parent_id: 1
    )
  end
  let(:submission_record) do
    SubmissionRecord.create!(
      id: 1,
      team_id: team.id,
      assignment_id: assignment1.id,
    )
  end

  #SET UP WEB TOKENS SO THAT WE CAN TEST HTTP RESPONSE REQUESTS
  let(:token) { JsonWebToken.encode({id: studenta.id}) }
  let(:Authorization) { "Bearer #{token}" }

  #INDEX TESTING
  # GET /api/v1/student_task (Get student tasks)

  describe 'GET /submission_records/:id' do
    context 'when the student is part of the team' do
      it 'allows access and returns a 200 status' do
        get "/submission_records/#{submission_record.id}", headers: valid_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the student is NOT part of the team' do
      it 'denies access and returns a 403 status' do
        get "/submission_records/#{submission_record.id}", headers: unauthorized_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when an invalid token is provided' do
      it 'returns a 401 status' do
        get "/submission_records/#{submission_record.id}", headers: invalid_headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /submission_records' do
    context 'when the student belongs to a team' do
      it 'retrieves submission records and returns a 200 status' do
        get "/submission_records", params: { team_id: team.id }, headers: valid_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).length).to be > 0
      end
    end

    context 'when the student does NOT belong to a team' do
      it 'denies access and returns a 403 status' do
        get "/submission_records", params: { team_id: team.id }, headers: unauthorized_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'Edge Cases' do
    context 'when requesting a non-existent submission record' do
      it 'returns a 404 status' do
        get "/submission_records/99999", headers: valid_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end