# frozen_string_literal: true

require 'rails_helper'
require 'swagger_helper'
require 'json_web_token'

RSpec.describe Api::V1::TeamsController, type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  # --------------------------------------------------------------------------
  # Common Test Data
  # --------------------------------------------------------------------------
  # A single institution to house all users.
  let(:institution) { Institution.create!(name: "NC State") }

  # An instructor user who will own assignments and courses.
  let(:instructor) do
    User.create!(
      name:                "profa",
      password_digest:     "password",
      role_id:              @roles[:instructor].id,
      full_name:           "Prof A",
      email:               "testuser@example.com",
      mru_directory_path:  "/home/testuser",
      institution_id:      institution.id
    )
  end

  # A generic "new participant" used when adding to teams
  let(:user) do
    User.create!(
      full_name:       "New Participant",
      name:            "NewParticipant",
      email:           "newparticipant@example.com",
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  # A student user used for ownership checks in update_duty, list, etc.
  let(:other_user) do
    User.create!(
      full_name:       "Student Member",
      name:            "student_member",
      email:           "studentmember@example.com",
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end
  
  # --------------------------------------------------------------------------
  # Primary Resources
  # --------------------------------------------------------------------------
  # Two assignments: one main and one alternate, both owned by the instructor.
  let(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  # A single course, also owned by the instructor.
  let(:course) do
    Course.create!(
      name:            "Sample Course",
      instructor_id:   instructor.id,
      institution_id:  institution.id,
      directory_path:  "/some/path"
    )
  end

  let(:team_owner) do
    User.create!(
      name:            "team_owner",
      full_name:       "Team Owner",
      email:           "team_owner@example.com",
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end
  let(:team_with_course) do
    CourseTeam.create!(
      parent_id:      course.id,
      name:           'team 2',
      user_id:        team_owner.id
    )
  end
  
  let(:team_with_assignment) do
    AssignmentTeam.create!(
      parent_id:      assignment.id,
      name:           'team 1',
      user_id:        team_owner.id
    )
  end

  # Create one participant record per context for a baseline student_user:
  let!(:participant_for_assignment) do
    AssignmentParticipant.create!(
      parent_id: assignment.id,
      user:      other_user,
      handle:    other_user.name
    )
  end
  let!(:participant_for_course) do
    CourseParticipant.create!(
      parent_id: course.id,
      user:      other_user,
      handle:    other_user.name
    )
  end

  # Link those participants into TeamsParticipant join records:
  let(:teams_participant_assignment) do
    TeamsParticipant.create!(
      participant_id: participant_for_assignment.id,
      team_id:        team_with_assignment.id,
      user_id:        participant_for_assignment.user_id
    )
  end
  let(:teams_participant_course) do
    TeamsParticipant.create!(
      participant_id: participant_for_course.id,
      team_id:        team_with_course.id,
      user_id:        participant_for_course.user_id
    )
  end

  let(:token) { JsonWebToken.encode(id: instructor.id) }
  let(:auth_headers) { { Authorization: "Bearer #{token}" } }

  describe 'GET /api/v1/teams' do
    it 'returns all teams' do
      team_with_course
      get '/api/v1/teams', headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(team_with_course.id)
    end
  end

  describe 'GET /api/v1/teams/:id' do
    it 'returns a specific team' do
      get "/api/v1/teams/#{team_with_course.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response['id']).to eq(team_with_course.id)
    end

    it 'returns 404 for non-existent team' do
      get '/api/v1/teams/0', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/teams' do
    it 'returns error for invalid params' do
      post '/api/v1/teams', params: { team: { name: '' } }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to have_key('errors')
    end
  end

  describe 'Team Members' do
    describe 'GET /api/v1/teams/:id/members' do
      it 'returns all team members' do
        teams_participant_course
        get "/api/v1/teams/#{team_with_course.id}/members", headers: auth_headers
        expect(response).to have_http_status(:success)
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(other_user.id)
      end
    end

    describe 'POST /api/v1/teams/:id/members' do
      let(:new_user) { create(:user) }
      let!(:new_participant) { create(:course_participant, user: new_user, parent_id: course.id) }

      let(:valid_participant_params) do
        {
          team_participant: {
            user_id: new_user.id
          }
        }
      end

      it 'adds a new team member' do
        expect {
          post "/api/v1/teams/#{team_with_course.id}/members", params: valid_participant_params, headers: auth_headers
        }.to change(TeamsParticipant, :count).by(1)
        expect(response).to have_http_status(:created)
        expect(json_response['id']).to eq(new_user.id)
      end

      it 'returns error when team is full' do
        # For AssignmentTeam, set max_team_size on the assignment, not the team
        assignment.update(max_team_size: 1)
        teams_participant_assignment # This creates the first member
        
        # Create a new participant for the assignment
        new_assignment_participant = create(:assignment_participant, user: new_user, parent_id: assignment.id)
        
        assignment_params = {
          team_participant: {
            user_id: new_user.id
          }
        }
        
        post "/api/v1/teams/#{team_with_assignment.id}/members", params: assignment_params, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to have_key('errors')
      end
    end

    describe 'DELETE /api/v1/teams/:id/members/:user_id' do
      it 'removes a team member' do
        teams_participant_course
        expect {
          delete "/api/v1/teams/#{team_with_course.id}/members/#{other_user.id}", headers: auth_headers
        }.to change(TeamsParticipant, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 for non-existent member' do
        delete "/api/v1/teams/#{team_with_course.id}/members/0", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
