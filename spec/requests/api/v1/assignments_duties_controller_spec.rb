# frozen_string_literal: true

require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Assignments duties API', type: :request do
  let!(:instructor_role) { Role.find_or_create_by!(name: 'Instructor') }
  let!(:student_role) { Role.find_or_create_by!(name: 'Student') }
  let!(:institution) { Institution.create!(name: 'NC State') }

  let!(:instructor) do
    User.create!(
      name: 'instructor_user',
      email: 'instructor@example.com',
      password: 'password123',
      full_name: 'Instructor User',
      role_id: instructor_role.id,
      institution_id: institution.id
    )
  end

  let!(:student) do
    User.create!(
      name: 'student_user',
      email: 'student@example.com',
      password: 'password123',
      full_name: 'Student User',
      role_id: student_role.id,
      institution_id: institution.id
    )
  end

  let!(:assignment) { Assignment.create!(name: 'Assignment A', instructor_id: instructor.id) }
  let!(:duty) { Duty.create!(name: 'Reviewer Duty', instructor_id: instructor.id) }
  let!(:assignment_duty) do
    AssignmentsDuty.create!(assignment_id: assignment.id, duty_id: duty.id, max_members_for_duty: 2)
  end

  let(:instructor_headers) do
    {
      'Authorization' => "Bearer #{JsonWebToken.encode({ id: instructor.id })}",
      'Content-Type' => 'application/json'
    }
  end

  let(:student_headers) do
    {
      'Authorization' => "Bearer #{JsonWebToken.encode({ id: student.id })}",
      'Content-Type' => 'application/json'
    }
  end

  describe 'GET /assignments/:id' do
    it 'includes assignment duties and role-based review flag' do
      get "/assignments/#{assignment.id}", headers: instructor_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['has_role_based_review']).to eq(true)
      expect(body['assignment_duties']).to be_an(Array)
      expect(body['assignment_duties'].first['duty_id']).to eq(duty.id)
      expect(body['assignment_duties'].first['max_members_for_duty']).to eq(2)
    end
  end

  describe 'PATCH /assignments/:assignment_id/duties/:id/limit' do
    it 'updates max members per duty for an assignment' do
      patch "/assignments/#{assignment.id}/duties/#{duty.id}/limit",
            params: { max_members_for_duty: 4 }.to_json,
            headers: instructor_headers

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['duty_id']).to eq(duty.id)
      expect(body['max_members_for_duty']).to eq(4)
      expect(assignment_duty.reload.max_members_for_duty).to eq(4)
    end

    it 'returns validation errors for invalid max members' do
      patch "/assignments/#{assignment.id}/duties/#{duty.id}/limit",
            params: { max_members_for_duty: 0 }.to_json,
            headers: instructor_headers

      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body['max_members_for_duty']).to be_an(Array)
    end

    it 'returns not found when duty is not assigned to assignment' do
      other_duty = Duty.create!(name: 'Mentor Duty', instructor_id: instructor.id)

      patch "/assignments/#{assignment.id}/duties/#{other_duty.id}/limit",
            params: { max_members_for_duty: 3 }.to_json,
            headers: instructor_headers

      expect(response).to have_http_status(:not_found)
      body = JSON.parse(response.body)
      expect(body['error']).to eq('Duty is not assigned to this assignment')
    end

    it 'forbids non-instructor users from changing limits' do
      patch "/assignments/#{assignment.id}/duties/#{duty.id}/limit",
            params: { max_members_for_duty: 3 }.to_json,
            headers: student_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
