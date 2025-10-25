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
    )
  end
  
  let(:team_with_assignment) do
    AssignmentTeam.create!(
      parent_id:      assignment.id,
      name:           'team 1',
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

  describe 'GET /teams' do
    it 'returns all teams' do
      team_with_course
      get '/teams', headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response.size).to eq(1)
      expect(json_response.first['id']).to eq(team_with_course.id)
    end

    it 'returns multiple teams of different types' do
      team_with_course
      team_with_assignment
      get '/teams', headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response.size).to eq(2)
    end
  end

  describe 'GET /teams/:id' do
    it 'returns a specific team' do
      get "/teams/#{team_with_course.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response['id']).to eq(team_with_course.id)
    end

    it 'returns team with correct parent_type using polymorphic method' do
      get "/teams/#{team_with_course.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response['parent_type']).to eq('course')
    end

    it 'returns assignment team with correct parent_type' do
      get "/teams/#{team_with_assignment.id}", headers: auth_headers
      expect(response).to have_http_status(:success)
      expect(json_response['parent_type']).to eq('assignment')
    end

    it 'returns 404 for non-existent team' do
      get '/teams/0', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /teams' do
    it 'returns error for invalid params' do
      post '/teams', params: { team: { name: '' } }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to have_key('errors')
    end

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
        team: {
          name: 'Invalid Team',
          type: 'InvalidTeam',
          parent_id: assignment.id
        }
      }
      
      post '/teams', params: invalid_params, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'Team Members' do
    describe 'GET /teams/:id/members' do
      it 'returns all team members' do
        teams_participant_course
        get "/teams/#{team_with_course.id}/members", headers: auth_headers
        expect(response).to have_http_status(:success)
        expect(json_response.size).to eq(1)
        expect(json_response.first['id']).to eq(other_user.id)
      end

      it 'returns empty array for team with no members' do
        get "/teams/#{team_with_course.id}/members", headers: auth_headers
        expect(response).to have_http_status(:success)
        expect(json_response).to be_empty
      end
    end

    describe 'POST /teams/:id/members' do
      let(:new_user) { create(:user) }

      context 'for CourseTeam' do
        let!(:new_participant) { create(:course_participant, user: new_user, parent_id: course.id) }

        let(:valid_participant_params) do
          {
            team_participant: {
              user_id: new_user.id
            }
          }
        end

        it 'adds a new team member using polymorphic participant_class' do
          expect {
            post "/teams/#{team_with_course.id}/members", params: valid_participant_params, headers: auth_headers
          }.to change(TeamsParticipant, :count).by(1)
          expect(response).to have_http_status(:created)
          expect(json_response['id']).to eq(new_user.id)
        end

        it 'returns error when user not a participant in course' do
          non_participant_user = create(:user)
          params = {
            team_participant: {
              user_id: non_participant_user.id
            }
          }
          
          post "/teams/#{team_with_course.id}/members", params: params, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].first).to match(/not a participant in this course/)
        end
      end

      context 'for AssignmentTeam' do
        let!(:new_assignment_participant) { create(:assignment_participant, user: new_user, parent_id: assignment.id) }

        let(:assignment_params) do
          {
            team_participant: {
              user_id: new_user.id
            }
          }
        end

        it 'adds a new team member using polymorphic participant_class' do
          expect {
            post "/teams/#{team_with_assignment.id}/members", params: assignment_params, headers: auth_headers
          }.to change(TeamsParticipant, :count).by(1)
          expect(response).to have_http_status(:created)
        end

        it 'returns error when team is full' do
          # Set max_team_size to 1 and add first member
          assignment.update(max_team_size: 1)
          teams_participant_assignment # This creates the first member
          
          # Try to add a second member when team is full
          post "/teams/#{team_with_assignment.id}/members", params: assignment_params, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].first).to match(/full capacity/)
        end

        it 'returns error when user not a participant in assignment' do
          non_participant_user = create(:user)
          params = {
            team_participant: {
              user_id: non_participant_user.id
            }
          }
          
          post "/teams/#{team_with_assignment.id}/members", params: params, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response['errors'].first).to match(/not a participant in this assignment/)
        end
      end

      context 'type validation' do
        it 'prevents adding CourseParticipant to AssignmentTeam' do
          # Create a course participant
          course_user = create(:user)
          course_participant = create(:course_participant, user: course_user, parent_id: course.id)
          
          # Try to add to assignment team (this should fail in the model layer)
          # The controller will find no participant because it looks for AssignmentParticipant
          params = {
            team_participant: {
              user_id: course_user.id
            }
          }
          
          post "/teams/#{team_with_assignment.id}/members", params: params, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'prevents adding AssignmentParticipant to CourseTeam' do
          # Create an assignment participant
          assignment_user = create(:user)
          assignment_participant = create(:assignment_participant, user: assignment_user, parent_id: assignment.id)
          
          # Try to add to course team (this should fail in the model layer)
          # The controller will find no participant because it looks for CourseParticipant
          params = {
            team_participant: {
              user_id: assignment_user.id
            }
          }
          
          post "/teams/#{team_with_course.id}/members", params: params, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe 'DELETE /teams/:id/members/:user_id' do
      it 'removes a team member' do
        teams_participant_course
        expect {
          delete "/teams/#{team_with_course.id}/members/#{other_user.id}", headers: auth_headers
        }.to change(TeamsParticipant, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'returns 404 for non-existent member' do
        delete "/teams/#{team_with_course.id}/members/0", headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      it 'removes member from assignment team' do
        teams_participant_assignment
        expect {
          delete "/teams/#{team_with_assignment.id}/members/#{other_user.id}", headers: auth_headers
        }.to change(TeamsParticipant, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end
    end
  end

  describe 'Polymorphic behavior' do
    it 'CourseTeam uses CourseParticipant class' do
      expect(team_with_course.participant_class).to eq(CourseParticipant)
    end

    it 'AssignmentTeam uses AssignmentParticipant class' do
      expect(team_with_assignment.participant_class).to eq(AssignmentParticipant)
    end

    it 'CourseTeam has correct parent_entity' do
      expect(team_with_course.parent_entity).to eq(course)
    end

    it 'AssignmentTeam has correct parent_entity' do
      expect(team_with_assignment.parent_entity).to eq(assignment)
    end

    it 'CourseTeam has correct context_label' do
      expect(team_with_course.context_label).to eq('course')
    end

    it 'AssignmentTeam has correct context_label' do
      expect(team_with_assignment.context_label).to eq('assignment')
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
