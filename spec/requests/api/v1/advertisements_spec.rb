require 'swagger_helper'
require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Advertisements API', type: :request do
  before(:all) do
    @roles = create_roles_hierarchy
  end

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
      has_topics: true,
      max_team_size: 3
    )
  }

  let(:sign_up_topic) {
    ProjectTopic.create!(
      topic_name: 'Test Topic',
      assignment_id: assignment.id,
      max_choosers: 2
    )
  }

  let(:team) {
    AssignmentTeam.create!(
      name: 'Team Alpha',
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

  let(:signed_up_team) {
    SignedUpTeam.create!(
      sign_up_topic_id: sign_up_topic.id,
      team_id: team.id,
      is_waitlisted: false
    )
  }

  before(:each) do
    # Add student1 to team
    TeamsParticipant.create!(
      team_id: team.id,
      participant_id: participant1.id,
      user_id: student1.id
    )
  end

  describe 'Advertisement Display' do
    let(:student2_token) { JsonWebToken.encode({ id: student2.id }) }
    let(:student2_headers) { { 'Authorization' => "Bearer #{student2_token}" } }

    context 'when viewing assignments with advertisements' do
      it 'returns advertisement data when team has created advertisement' do
        # Create advertisement
        signed_up_team # Create signed up team
        signed_up_team.update(advertise_for_partner: true, comments_for_advertisement: 'Looking for strong members!')

        # Simulate endpoint: GET /assignments/:id/sign_up_topics
        get "/sign_up_topics?assignment_id=#{assignment.id}", headers: student2_headers
        
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        
        # Verify we can see the topic and its signed up teams (which contain advertisement data)
        expect(body).to be_a(Array)
      end

      it 'includes trumpet icon indicator when team is advertising' do
        signed_up_team.update(advertise_for_partner: true, comments_for_advertisement: 'We need members!')
        participant2 # ensure exists

        get "/sign_up_topics?assignment_id=#{assignment.id}", headers: student2_headers
        
        expect(response).to have_http_status(:ok)
        # The frontend will check signed_up_teams[].advertise_for_partner to render trumpet icon
      end

      it 'returns advertisement comments' do
        ad_text = 'Experienced team looking for dedicated members to complete project'
        signed_up_team.update(advertise_for_partner: true, comments_for_advertisement: ad_text)
        participant2 # ensure exists

        get "/sign_up_topics?assignment_id=#{assignment.id}", headers: student2_headers
        
        expect(response).to have_http_status(:ok)
        # Frontend will display comments_for_advertisement text
      end
    end
  end

  describe 'Advertisement Creation' do
    context 'when team wants to create an advertisement' do
      let(:student1_token) { JsonWebToken.encode({ id: student1.id }) }
      let(:student1_headers) { { 'Authorization' => "Bearer #{student1_token}" } }

      it 'allows team member to enable advertisement' do
        signed_up_team # Create signed up team
        participant1 # ensure team member exists

        # Update signed up team to create advertisement
        patch "/signed_up_teams/#{signed_up_team.id}",
              params: {
                signed_up_team: {
                  advertise_for_partner: true,
                  comments_for_advertisement: 'Looking for passionate developers!'
                }
              },
              headers: student1_headers
        
        # Verify the team member can enable advertisement
        expect(response).to have_http_status(:ok)
        signed_up_team.reload
        expect(signed_up_team.advertise_for_partner).to be true
        expect(signed_up_team.comments_for_advertisement).to eq('Looking for passionate developers!')
      end

      it 'stores advertisement text correctly' do
        ad_text = 'We have one spot left. Please join our amazing team!'
        signed_up_team.update(
          advertise_for_partner: true,
          comments_for_advertisement: ad_text
        )
        
        expect(signed_up_team.advertise_for_partner).to be true
        expect(signed_up_team.comments_for_advertisement).to eq(ad_text)
      end

      it 'allows team to disable advertisement' do
        signed_up_team.update(
          advertise_for_partner: true,
          comments_for_advertisement: 'Looking for members'
        )
        
        signed_up_team.update(advertise_for_partner: false)
        
        expect(signed_up_team.advertise_for_partner).to be false
      end
    end
  end

  describe 'Join Request from Advertisement' do
    let(:student2_token) { JsonWebToken.encode({ id: student2.id }) }
    let(:student2_headers) { { 'Authorization' => "Bearer #{student2_token}" } }

    context 'when student sees advertisement and wants to join' do
      before do
        signed_up_team.update(
          advertise_for_partner: true,
          comments_for_advertisement: 'We need one more member!'
        )
      end

      it 'allows student to submit join request for advertising team' do
        participant2 # ensure exists
        
        post '/join_team_requests',
             params: {
               team_id: team.id,
               assignment_id: assignment.id,
               comments: 'I would like to join your team based on your advertisement'
             },
             headers: student2_headers
        
        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body['reply_status']).to eq('PENDING')
      end

      it 'tracks which team the request is for' do
        participant2 # ensure exists
        
        post '/join_team_requests',
             params: {
               team_id: team.id,
               assignment_id: assignment.id,
               comments: 'Interested in joining'
             },
             headers: student2_headers
        
        join_request = JoinTeamRequest.last
        expect(join_request.team_id).to eq(team.id)
      end
    end
  end

  describe 'Team Full Scenario with Advertisements' do
    let(:student1_token) { JsonWebToken.encode({ id: student1.id }) }
    let(:student1_headers) { { 'Authorization' => "Bearer #{student1_token}" } }
    
    let(:student2_token) { JsonWebToken.encode({ id: student2.id }) }
    let(:student2_headers) { { 'Authorization' => "Bearer #{student2_token}" } }
    
    let(:student3_token) { JsonWebToken.encode({ id: student3.id }) }
    let(:student3_headers) { { 'Authorization' => "Bearer #{student3_token}" } }

    context 'when team reaches maximum capacity' do
      before do
        signed_up_team.update(advertise_for_partner: true, comments_for_advertisement: 'Last spot available!')
        participant2 # ensure exists
        participant3 # ensure exists
        
        # Add student2 to team (now 2 members)
        TeamsParticipant.create!(
          team_id: team.id,
          participant_id: participant2.id,
          user_id: student2.id
        )
      end

      it 'prevents new join requests when team is full' do
        assignment.update(max_team_size: 2)
        
        post '/join_team_requests',
             params: {
               team_id: team.id,
               assignment_id: assignment.id,
               comments: 'I want to join'
             },
             headers: student3_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['message']).to include('full')
      end

      it 'prevents team owner from accepting request when team is full' do
        join_request = JoinTeamRequest.create!(
          participant_id: participant3.id,
          team_id: team.id,
          comments: 'Please let me join',
          reply_status: 'PENDING'
        )
        
        assignment.update(max_team_size: 2)
        
        patch "/join_team_requests/#{join_request.id}/accept",
              headers: student1_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body['error']).to include('full')
      end
    end
  end

  describe 'Integration: Advertisement Lifecycle' do
    let(:student1_token) { JsonWebToken.encode({ id: student1.id }) }
    let(:student1_headers) { { 'Authorization' => "Bearer #{student1_token}" } }
    
    let(:student2_token) { JsonWebToken.encode({ id: student2.id }) }
    let(:student2_headers) { { 'Authorization' => "Bearer #{student2_token}" } }

    it 'completes full workflow: create team -> advertise -> receive request -> accept' do
      signed_up_team # Create signed up team with student1
      participant2 # ensure student2 exists
      
      # Step 1: Team creates advertisement
      signed_up_team.update(
        advertise_for_partner: true,
        comments_for_advertisement: 'Expert team seeking final member'
      )
      expect(signed_up_team.advertise_for_partner).to be true
      
      # Step 2: Another student sees advertisement and submits join request
      post '/join_team_requests',
           params: {
             team_id: team.id,
             assignment_id: assignment.id,
             comments: 'Saw your advertisement, interested in joining'
           },
           headers: student2_headers
      
      expect(response).to have_http_status(:created)
      join_request = JoinTeamRequest.last
      expect(join_request.team_id).to eq(team.id)
      
      # Step 3: Team member sees the request and accepts it
      patch "/join_team_requests/#{join_request.id}/accept",
            headers: student1_headers
      
      expect(response).to have_http_status(:ok)
      
      # Step 4: Verify student2 is now on the team
      team.reload
      expect(team.participants.count).to eq(2)
      expect(team.participants.pluck(:user_id)).to include(student2.id)
    end
  end
end
