# frozen_string_literal: true

require 'swagger_helper'
require 'json_web_token'

RSpec.describe 'Responses Task Order', type: :request do
  include RolesHelper

  before(:each) do
    @roles = create_roles_hierarchy
  end

  let!(:instructor) do
    User.create!(
      name:            "instructor_ro_#{SecureRandom.hex(4)}",
      password_digest: "password",
      role_id:         @roles[:instructor].id,
      full_name:       "Instructor RO",
      email:           "instructor_ro_#{SecureRandom.hex(4)}@example.com"
    )
  end

  let!(:student) do
    User.create!(
      name:            "student_ro_#{SecureRandom.hex(4)}",
      password_digest: "password",
      role_id:         @roles[:student].id,
      full_name:       "Student RO",
      email:           "student_ro_#{SecureRandom.hex(4)}@example.com"
    )
  end

  # Use a plain named helper — avoid `let(:Authorization)` which collides with
  # the Rails Authorization module and causes `split' for module Authorization`.
  let(:token)       { JsonWebToken.encode({ id: student.id }) }
  let(:auth_header) { { 'Authorization' => "Bearer #{token}" } }

  let!(:assignment) do
    Assignment.create!(
      name:       "RO Assignment #{SecureRandom.hex(4)}",
      instructor: instructor
    )
  end

  let!(:reviewer_participant) do
    AssignmentParticipant.create!(
      user_id:   student.id,
      parent_id: assignment.id,
      handle:    student.name
    )
  end

  let!(:reviewee_participant) do
    AssignmentParticipant.create!(
      user_id:   instructor.id,
      parent_id: assignment.id,
      handle:    instructor.name
    )
  end

  let!(:team) do
    AssignmentTeam.create!(
      name:      "RO Team #{SecureRandom.hex(4)}",
      parent_id: assignment.id
    )
  end

  let!(:teams_participant) do
    TeamsParticipant.create!(
      team:        team,
      participant: reviewer_participant,
      user:        student
    )
  end

  let!(:review_map) do
    map = ReviewResponseMap.new(
      reviewer_id:        reviewer_participant.id,
      reviewee_id:        reviewee_participant.id,
      reviewed_object_id: assignment.id
    )
    map.save!(validate: false)
    map
  end

  let!(:quiz_map) do
    map = QuizResponseMap.new(
      reviewer_id:        reviewer_participant.id,
      reviewee_id:        reviewee_participant.id,
      reviewed_object_id: assignment.id
    )
    map.save!(validate: false)
    map
  end

  # ---------------------------------------------------------------------------
  # POST /responses — order gating
  # ---------------------------------------------------------------------------
  describe 'POST /responses' do
    context 'when prior quiz task is NOT yet submitted' do
      it 'blocks creating a review response (prior task incomplete)' do
        post '/responses',
             params:  { response_map_id: review_map.id, round: 1 },
             headers: auth_header

        expect([403, 412, 422]).to include(response.status)
      end
    end

    context 'when prior quiz task IS submitted' do
      before do
        Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)
      end

      it 'allows creating a review response' do
        post '/responses',
             params:  { response_map_id: review_map.id, round: 1 },
             headers: auth_header

        expect(response.status).to eq(201)
      end
    end

    context 'when token is invalid' do
      it 'returns 401 with Not Authorized' do
        post '/responses',
             params:  { response_map_id: review_map.id, round: 1 },
             headers: { 'Authorization' => 'Bearer ' }

        data = JSON.parse(response.body)
        expect(data['error']).to eq('Not Authorized')
      end
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /responses/:id — order gating on update/submit
  # ---------------------------------------------------------------------------
  describe 'PATCH /responses/:id' do
    let!(:review_response) do
      Response.create!(
        map_id:       review_map.id,
        round:        1,
        is_submitted: false
      )
    end

    context 'when prior quiz task is NOT yet submitted' do
      it 'blocks submitting the review response' do
        patch "/responses/#{review_response.id}",
              params:  { is_submitted: true },
              headers: auth_header

        expect([403, 412, 422]).to include(response.status)
      end
    end

    context 'when prior quiz task IS submitted' do
      before do
        Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)
      end

      it 'allows submitting the review response' do
        patch "/responses/#{review_response.id}",
              params:  { is_submitted: true },
              headers: auth_header

        expect(response.status).to eq(200)
        data = JSON.parse(response.body)
        expect(data['submitted']).to be true
      end
    end

    context 'when updating a field without submitting' do
      before do
        Response.create!(map_id: quiz_map.id, round: 1, is_submitted: true)
      end

      it 'preserves authorization checks and updates successfully' do
        patch "/responses/#{review_response.id}",
              params:  { additional_comment: 'Updated comment' },
              headers: auth_header

        expect(response.status).to eq(200)
      end
    end

    context 'when token is invalid' do
      it 'returns 401 with Not Authorized' do
        patch "/responses/#{review_response.id}",
              params:  { is_submitted: true },
              headers: { 'Authorization' => 'Bearer ' }

        data = JSON.parse(response.body)
        expect(data['error']).to eq('Not Authorized')
      end
    end
  end
end