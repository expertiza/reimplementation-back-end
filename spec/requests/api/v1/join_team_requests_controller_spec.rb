require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe 'JoinTeamRequests API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:admin) {
    User.create!(
      name: "admin_user",
      password_digest: BCrypt::Password.create("password"),
      role_id: @roles[:admin].id,
      full_name: "Admin User",
      email: "admin@example.com"
    )
  }

  let(:instructor) {
    User.create!(
      name: "instructor_user",
      password_digest: BCrypt::Password.create("password"),
      role_id: @roles[:instructor].id,
      full_name: "Instructor User",
      email: "instructor@example.com"
    )
  }

  let(:student1) {
    User.create!(
      name: "student1",
      password_digest: BCrypt::Password.create("password"),
      role_id: @roles[:student].id,
      full_name: "Student One",
      email: "student1@example.com"
    )
  }

  let(:student2) {
    User.create!(
      name: "student2",
      password_digest: BCrypt::Password.create("password"),
      role_id: @roles[:student].id,
      full_name: "Student Two",
      email: "student2@example.com"
    )
  }

  let(:student3) {
    User.create!(
      name: "student3",
      password_digest: BCrypt::Password.create("password"),
      role_id: @roles[:student].id,
      full_name: "Student Three",
      email: "student3@example.com"
    )
  }

  let(:assignment) {
    Assignment.create!(
      name: 'Test Assignment',
      instructor_id: instructor.id,
      has_teams: true,
      max_team_size: 3
    )
  }

  let(:team1) {
    AssignmentTeam.create!(
      name: 'Team 1',
      parent_id: assignment.id,
      type: 'AssignmentTeam'
    )
  }

  let(:participant1) {
    AssignmentParticipant.create!(
      user_id: student1.id,
      parent_id: assignment.id,
      type: 'AssignmentParticipant',
      handle: 'student1_handle'
    )
  }

  let(:participant2) {
    AssignmentParticipant.create!(
      user_id: student2.id,
      parent_id: assignment.id,
      type: 'AssignmentParticipant',
      handle: 'student2_handle'
    )
  }

  let(:participant3) {
    AssignmentParticipant.create!(
      user_id: student3.id,
      parent_id: assignment.id,
      type: 'AssignmentParticipant',
      handle: 'student3_handle'
    )
  }

  let(:join_team_request) {
    JoinTeamRequest.create!(
      participant_id: participant2.id,
      team_id: team1.id,
      comments: 'Please let me join your team',
      reply_status: 'PENDING'
    )
  }

  before(:each) do
    # Add student1 to team1
    TeamsParticipant.create!(
      team_id: team1.id,
      participant_id: participant1.id,
      user_id: student1.id
    )
  end

  describe 'Authorization Tests' do
    context 'when user is admin' do
      let(:admin_token) { JsonWebToken.encode({id: admin.id}) }
      let(:admin_headers) { { 'Authorization' => "Bearer #{admin_token}" } }

      it 'allows admin to view all join team requests' do
        join_team_request # Create the request
        get '/api/v1/join_team_requests', headers: admin_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is student trying to access index' do
      let(:student_token) { JsonWebToken.encode({id: student1.id}) }
      let(:student_headers) { { 'Authorization' => "Bearer #{student_token}" } }

      it 'denies student access to index action' do
        get '/api/v1/join_team_requests', headers: student_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when student creates a join team request' do
      let(:student2_token) { JsonWebToken.encode({id: student2.id}) }
      let(:student2_headers) { { 'Authorization' => "Bearer #{student2_token}" } }

      it 'allows student to create a request' do
        participant2 # Ensure participant exists
        post '/api/v1/join_team_requests',
             params: {
               team_id: team1.id,
               assignment_id: assignment.id,
               comments: 'I want to join'
             },
             headers: student2_headers
        expect(response).to have_http_status(:created)
      end

      it 'prevents student from joining a full team' do
        # Fill the team to max capacity
        assignment.update!(max_team_size: 1)
        participant2 # Ensure participant exists
        
        post '/api/v1/join_team_requests',
             params: {
               team_id: team1.id,
               assignment_id: assignment.id,
               comments: 'I want to join'
             },
             headers: student2_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to eq('This team is full.')
      end
    end

    context 'when viewing a join team request' do
      let(:creator_token) { JsonWebToken.encode({id: student2.id}) }
      let(:creator_headers) { { 'Authorization' => "Bearer #{creator_token}" } }
      
      let(:team_member_token) { JsonWebToken.encode({id: student1.id}) }
      let(:team_member_headers) { { 'Authorization' => "Bearer #{team_member_token}" } }
      
      let(:outsider_token) { JsonWebToken.encode({id: student3.id}) }
      let(:outsider_headers) { { 'Authorization' => "Bearer #{outsider_token}" } }

      it 'allows the request creator to view their own request' do
        participant2 # Ensure participant exists
        get "/api/v1/join_team_requests/#{join_team_request.id}", headers: creator_headers
        expect(response).to have_http_status(:ok)
      end

      it 'allows team members to view requests to their team' do
        participant1 # Ensure participant exists
        get "/api/v1/join_team_requests/#{join_team_request.id}", headers: team_member_headers
        expect(response).to have_http_status(:ok)
      end

      it 'denies access to students not involved in the request' do
        participant3 # Ensure participant exists
        get "/api/v1/join_team_requests/#{join_team_request.id}", headers: outsider_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when updating a join team request' do
      let(:creator_token) { JsonWebToken.encode({id: student2.id}) }
      let(:creator_headers) { { 'Authorization' => "Bearer #{creator_token}" } }
      
      let(:team_member_token) { JsonWebToken.encode({id: student1.id}) }
      let(:team_member_headers) { { 'Authorization' => "Bearer #{team_member_token}" } }

      it 'allows the request creator to update their own request' do
        participant2 # Ensure participant exists
        patch "/api/v1/join_team_requests/#{join_team_request.id}",
              params: { join_team_request: { comments: 'Updated comment' } },
              headers: creator_headers
        expect(response).to have_http_status(:ok)
      end

      it 'denies team members from updating the request' do
        participant1 # Ensure participant exists
        patch "/api/v1/join_team_requests/#{join_team_request.id}",
              params: { join_team_request: { comments: 'Updated comment' } },
              headers: team_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when deleting a join team request' do
      let(:creator_token) { JsonWebToken.encode({id: student2.id}) }
      let(:creator_headers) { { 'Authorization' => "Bearer #{creator_token}" } }
      
      let(:team_member_token) { JsonWebToken.encode({id: student1.id}) }
      let(:team_member_headers) { { 'Authorization' => "Bearer #{team_member_token}" } }

      it 'allows the request creator to delete their own request' do
        participant2 # Ensure participant exists
        delete "/api/v1/join_team_requests/#{join_team_request.id}", headers: creator_headers
        expect(response).to have_http_status(:ok)
      end

      it 'denies team members from deleting the request' do
        participant1 # Ensure participant exists
        delete "/api/v1/join_team_requests/#{join_team_request.id}", headers: team_member_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when declining a join team request' do
      let(:creator_token) { JsonWebToken.encode({id: student2.id}) }
      let(:creator_headers) { { 'Authorization' => "Bearer #{creator_token}" } }
      
      let(:team_member_token) { JsonWebToken.encode({id: student1.id}) }
      let(:team_member_headers) { { 'Authorization' => "Bearer #{team_member_token}" } }
      
      let(:outsider_token) { JsonWebToken.encode({id: student3.id}) }
      let(:outsider_headers) { { 'Authorization' => "Bearer #{outsider_token}" } }

      it 'allows team members to decline a request' do
        participant1 # Ensure participant exists
        patch "/api/v1/join_team_requests/#{join_team_request.id}/decline", headers: team_member_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Join team request declined successfully')
      end

      it 'denies the request creator from declining their own request' do
        participant2 # Ensure participant exists
        patch "/api/v1/join_team_requests/#{join_team_request.id}/decline", headers: creator_headers
        expect(response).to have_http_status(:forbidden)
      end

      it 'denies outsiders from declining the request' do
        participant3 # Ensure participant exists
        patch "/api/v1/join_team_requests/#{join_team_request.id}/decline", headers: outsider_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when accepting a join team request' do
      let(:team_member_token) { JsonWebToken.encode({id: student1.id}) }
      let(:team_member_headers) { { 'Authorization' => "Bearer #{team_member_token}" } }
      
      let(:creator_token) { JsonWebToken.encode({id: student2.id}) }
      let(:creator_headers) { { 'Authorization' => "Bearer #{creator_token}" } }

      it 'allows team members to accept a request' do
        participant1 # Ensure participant exists
        patch "/api/v1/join_team_requests/#{join_team_request.id}/accept", headers: team_member_headers
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Join team request accepted successfully')
        
        # Verify participant was added to team
        expect(team1.participants.reload).to include(participant2)
      end

      it 'denies the request creator from accepting their own request' do
        participant2 # Ensure participant exists
        patch "/api/v1/join_team_requests/#{join_team_request.id}/accept", headers: creator_headers
        expect(response).to have_http_status(:forbidden)
      end

      it 'prevents accepting when team is full' do
        # Fill the team to max capacity
        assignment.update!(max_team_size: 1)
        participant1 # Ensure participant exists
        
        patch "/api/v1/join_team_requests/#{join_team_request.id}/accept", headers: team_member_headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Team is full')
      end
    end

    context 'when filtering join team requests' do
      let(:student_token) { JsonWebToken.encode({id: student1.id}) }
      let(:student_headers) { { 'Authorization' => "Bearer #{student_token}" } }

      it 'gets requests for a specific team' do
        participant2 # Ensure participant exists
        join_team_request # Create the request
        
        get "/api/v1/join_team_requests/for_team/#{team1.id}", headers: student_headers
        expect(response).to have_http_status(:ok)
        
        data = JSON.parse(response.body)
        expect(data).to be_an(Array)
        expect(data.length).to be >= 1
      end

      it 'gets requests by a specific user' do
        participant2 # Ensure participant exists
        join_team_request # Create the request
        
        get "/api/v1/join_team_requests/by_user/#{student2.id}", headers: student_headers
        expect(response).to have_http_status(:ok)
        
        data = JSON.parse(response.body)
        expect(data).to be_an(Array)
      end

      it 'gets only pending requests' do
        participant2 # Ensure participant exists
        join_team_request # Create the request
        
        get "/api/v1/join_team_requests/pending", headers: student_headers
        expect(response).to have_http_status(:ok)
        
        data = JSON.parse(response.body)
        expect(data).to be_an(Array)
        expect(data.all? { |req| req['reply_status'] == 'PENDING' }).to be true
      end
    end
  end
end
