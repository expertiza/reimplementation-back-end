# frozen_string_literal: true

require 'rails_helper'
require 'swagger_helper'
require 'json_web_token'

RSpec.describe TeamsController, type: :request do
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

  # --- FactoryBot Setup ---
  let!(:course) { create(:course, instructor: instructor) }
  let!(:assignment) { create(:assignment, instructor: instructor, max_team_size: 3) }
  let!(:course_team) { create(:course_team, course: course) }
  let!(:assignment_team) { create(:assignment_team, assignment: assignment) }

  # --- Auth & Helpers ---
  let(:token) { JsonWebToken.encode(id: instructor.id) }
  let(:auth_headers) { { Authorization: "Bearer #{token}" } }
  let(:json_response) { JSON.parse(response.body) }

  # --- Controller Action Tests ---
  describe 'GET /teams' do
    it 'returns all teams of different types' do
      # The let! blocks for course_team and assignment_team
      # have already created these.
      get '/teams', headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response.size).to eq(2)
      expect(json_response.map { |t| t['id'] }).to include(course_team.id, assignment_team.id)
    end
  end

  describe 'GET /teams/:id' do
    it 'returns a specific course team' do
      get "/teams/#{course_team.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response['id']).to eq(course_team.id)
      expect(json_response['parent_type']).to eq('course') # Check polymorphic method
    end

    it 'returns a specific assignment team' do
      get "/teams/#{assignment_team.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response['id']).to eq(assignment_team.id)
      expect(json_response['parent_type']).to eq('assignment') # Check polymorphic method
    end

    it 'returns 404 for non-existent team' do
      get '/teams/0', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /teams' do
    it 'creates an AssignmentTeam with valid params' do
      valid_params = {
        team: {
          name: 'New Assignment Team',
          type: 'AssignmentTeam',
          parent_id: assignment.id
        }
      }

      expect {
        post '/teams', params: valid_params, headers: auth_headers
      }.to change(AssignmentTeam, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['name']).to eq('New Assignment Team')
    end

    it 'creates a CourseTeam with valid params' do
      valid_params = {
        team: {
          name: 'New Course Team',
          type: 'CourseTeam',
          parent_id: course.id
        }
      }

      expect {
        post '/teams', params: valid_params, headers: auth_headers
      }.to change(CourseTeam, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json_response['name']).to eq('New Course Team')
    end

    it 'rejects invalid team type' do
      invalid_params = {
        team: { name: 'Invalid Team', type: 'InvalidTeam', parent_id: assignment.id }
      }

      post '/teams', params: invalid_params, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns error for missing params' do
      post '/teams', params: { team: { name: '' } }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to have_key('errors')
    end
  end

  describe 'Team Members' do
    let!(:new_user) { create(:user) }

    describe 'GET /teams/:id/members' do
      it 'returns all team members' do
        participant = create(:course_participant, course: course)
        course_team.add_member(participant)

        get "/teams/#{course_team.id}/members", headers: auth_headers
        expect(response).to have_http_status(:success)
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(participant.user.id)
      end

      it 'returns empty array for team with no members' do
        get "/teams/#{course_team.id}/members", headers: auth_headers
        expect(response).to have_http_status(:success)
        expect(json_response).to be_empty
      end
    end

    describe 'POST /teams/:id/members' do
      let(:participant_params) { { team_participant: { user_id: new_user.id } } }

      context 'for CourseTeam' do
        # Create the participant record so the controller can find them
        let!(:new_participant) { create(:course_participant, user: new_user, course: course) }

        it 'adds a new team member' do
          expect {
            post "/teams/#{course_team.id}/members", params: participant_params, headers: auth_headers
          }.to change(TeamsParticipant, :count).by(1)
          expect(response).to have_http_status(:created)
          expect(json_response['id']).to eq(new_user.id)
        end

        it 'returns error when user is not a participant in course' do
          non_participant_user = create(:user)
          params = { team_participant: { user_id: non_participant_user.id } }

          post "/teams/#{course_team.id}/members", params: params, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].first).to match(/not a participant in this course/)
        end
      end

      context 'for AssignmentTeam' do
        # Create the participant record
        let!(:new_assignment_participant) { create(:assignment_participant, user: new_user, assignment: assignment) }

        it 'adds a new team member' do
          expect {
            post "/teams/#{assignment_team.id}/members", params: participant_params, headers: auth_headers
          }.to change(TeamsParticipant, :count).by(1)
          expect(response).to have_http_status(:created)
        end

        it 'returns error when team is full' do
          assignment.update!(max_team_size: 1)
          first_participant = create(:assignment_participant, assignment: assignment)
          assignment_team.add_member(first_participant)

          # Try to add the second member (new_user)
          post "/teams/#{assignment_team.id}/members", params: participant_params, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].first).to match(/full capacity/)
        end

        it 'returns error when user not a participant in assignment' do
          non_participant_user = create(:user)
          params = { team_participant: { user_id: non_participant_user.id } }

          post "/teams/#{assignment_team.id}/members", params: params, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].first).to match(/not a participant in this assignment/)
        end
      end
    end

    describe 'DELETE /teams/:id/members/:user_id' do
      it 'removes a team member from a course team' do
        participant = create(:course_participant, course: course)
        course_team.add_member(participant)

        expect {
          delete "/teams/#{course_team.id}/members/#{participant.user.id}", headers: auth_headers
        }.to change(TeamsParticipant, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'removes a team member from an assignment team' do
        participant = create(:assignment_participant, assignment: assignment)
        assignment_team.add_member(participant)

        expect {
          delete "/teams/#{assignment_team.id}/members/#{participant.user.id}", headers: auth_headers
        }.to change(TeamsParticipant, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 for non-existent member' do
        delete "/teams/#{course_team.id}/members/0", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
