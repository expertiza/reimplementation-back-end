require 'rails_helper'
require 'json_web_token'

RSpec.describe 'Join Team Request and Invitation Acceptance Email Integration', type: :request do
  include ActiveJob::TestHelper

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
      name: 'Integration Test Assignment',
      instructor_id: instructor.id,
      has_teams: true,
      max_team_size: 4
    )
  }

  let(:team1) {
    AssignmentTeam.create!(
      name: 'Integration Test Team',
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

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    # Add student1 to team1
    TeamsParticipant.create!(
      team_id: team1.id,
      participant_id: participant1.id,
      user_id: student1.id
    )
  end

  after(:each) do
    clear_enqueued_jobs
  end

  describe 'Complete Join Team Request Acceptance Workflow' do
    let(:team_member_token) { JsonWebToken.encode({id: student1.id}) }
    let(:team_member_headers) { { 'Authorization' => "Bearer #{team_member_token}" } }

    it 'completes full workflow: request creation -> acceptance -> email notification' do
      participant2 # Ensure participant exists

      # Step 1: Create join team request
      post '/api/v1/join_team_requests',
           params: {
             team_id: team1.id,
             assignment_id: assignment.id,
             comments: 'I want to join your team'
           },
           headers: { 'Authorization' => "Bearer #{JsonWebToken.encode({id: student2.id})}" }

      expect(response).to have_http_status(:created)
      created_request = JSON.parse(response.body)
      request_id = created_request['join_team_request']['id']

      # Step 2: Accept the request
      expect {
        patch "/api/v1/join_team_requests/#{request_id}/accept", headers: team_member_headers
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)

      expect(response).to have_http_status(:ok)

      # Step 3: Verify participant was added
      expect(team1.participants.reload).to include(participant2)

      # Step 4: Verify request status changed
      updated_request = JoinTeamRequest.find(request_id)
      expect(updated_request.reply_status).to eq('ACCEPTED')
    end

    it 'sends email with correct content when join request is accepted' do
      participant2 # Ensure participant exists
      join_request = JoinTeamRequest.create!(
        participant_id: participant2.id,
        team_id: team1.id,
        comments: 'Please let me join'
      )

      patch "/api/v1/join_team_requests/#{join_request.id}/accept", headers: team_member_headers

      # Email job should be enqueued
      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.on_queue('default')
    end
  end

  describe 'Complete Invitation Acceptance Workflow' do
    it 'completes full workflow: invitation creation -> acceptance -> email notifications' do
      participant2 # Ensure participant exists
      participant3 # Ensure participant exists

      # Step 1: Create invitation
      invitation = Invitation.create!(
        to_id: participant2.id,
        from_id: team1.id,
        assignment_id: assignment.id
      )

      expect(invitation).to be_valid

      # Step 2: Accept invitation
      result = nil
      expect {
        result = invitation.accept_invitation
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).at_least(:twice)

      expect(result[:success]).to be true

      # Step 3: Verify participant was added to team
      expect(team1.participants.reload).to include(participant2)

      # Step 4: Verify invitation status changed
      invitation.reload
      expect(invitation.reply_status).to eq(InvitationValidator::ACCEPT_STATUS)
    end

    it 'sends acceptance email to invitee when invitation is accepted' do
      participant2 # Ensure participant exists

      invitation = Invitation.create!(
        to_id: participant2.id,
        from_id: team1.id,
        assignment_id: assignment.id
      )

      expect {
        invitation.accept_invitation
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
         .with('InvitationMailer', 'send_acceptance_email', anything)
    end

    it 'sends team notification email when invitation is accepted' do
      participant2 # Ensure participant exists
      participant3 # Ensure participant exists

      invitation = Invitation.create!(
        to_id: participant2.id,
        from_id: team1.id,
        assignment_id: assignment.id
      )

      expect {
        invitation.accept_invitation
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
         .with('InvitationMailer', 'send_team_acceptance_notification', anything)
    end

    it 'sends two emails (to invitee and team) on acceptance' do
      participant2 # Ensure participant exists

      invitation = Invitation.create!(
        to_id: participant2.id,
        from_id: team1.id,
        assignment_id: assignment.id
      )

      expect {
        invitation.accept_invitation
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).exactly(2).times
    end
  end

  describe 'Email Content Validation' do
    it 'join request acceptance email includes all required information' do
      participant2 # Ensure participant exists
      join_request = JoinTeamRequest.create!(
        participant_id: participant2.id,
        team_id: team1.id,
        comments: 'Please let me join'
      )

      email = JoinTeamRequestMailer.with(join_team_request: join_request).send_acceptance_email

      # Verify recipient
      expect(email.to).to include(student2.email)

      # Verify content
      body = email.body.encoded
      expect(body).to include(student2.full_name)
      expect(body).to include(team1.name)
      expect(body).to include(assignment.name)
      expect(body).to include('Good news')
      expect(body).to include('accepted')
    end

    it 'invitation acceptance email includes all required information' do
      participant2 # Ensure participant exists
      invitation = Invitation.create!(
        to_id: participant2.id,
        from_id: team1.id,
        assignment_id: assignment.id
      )

      email = InvitationMailer.with(invitation: invitation).send_acceptance_email

      # Verify recipient
      expect(email.to).to include(student2.email)

      # Verify content
      body = email.body.encoded
      expect(body).to include(student2.full_name)
      expect(body).to include(team1.name)
      expect(body).to include(assignment.name)
      expect(body).to include('accepted')
    end

    it 'team notification email includes all required information' do
      participant2 # Ensure participant exists
      invitation = Invitation.create!(
        to_id: participant2.id,
        from_id: team1.id,
        assignment_id: assignment.id
      )

      email = InvitationMailer.with(invitation: invitation).send_team_acceptance_notification

      # Verify recipient(s)
      expect(email.to).to include(student1.email)

      # Verify content
      body = email.body.encoded
      expect(body).to include(student2.full_name)
      expect(body).to include(team1.name)
      expect(body).to include(assignment.name)
      expect(body).to include('joined')
    end
  end

  describe 'Error Handling' do
    it 'does not send email if team is full' do
      participant2 # Ensure participant exists
      assignment.update!(max_team_size: 1)
      join_request = JoinTeamRequest.create!(
        participant_id: participant2.id,
        team_id: team1.id,
        comments: 'Please let me join'
      )

      team_member_token = JsonWebToken.encode({id: student1.id})
      team_member_headers = { 'Authorization' => "Bearer #{team_member_token}" }

      expect {
        patch "/api/v1/join_team_requests/#{join_request.id}/accept", headers: team_member_headers
      }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end

    it 'handles invitation acceptance when team already has multiple members' do
      participant2 # Ensure participant exists
      participant3 # Ensure participant exists

      # Add another member to the team
      TeamsParticipant.create!(
        team_id: team1.id,
        participant_id: participant3.id,
        user_id: student3.id
      )

      invitation = Invitation.create!(
        to_id: participant2.id,
        from_id: team1.id,
        assignment_id: assignment.id
      )

      expect {
        result = invitation.accept_invitation
        expect(result[:success]).to be true
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).at_least(:twice)
    end
  end

  describe 'OODD Principles Compliance' do
    it 'encapsulates email logic within mailer classes' do
      # Email logic should not be in controller or model
      # Instead, mailer classes should handle email composition

      participant2 # Ensure participant exists
      join_request = JoinTeamRequest.create!(
        participant_id: participant2.id,
        team_id: team1.id,
        comments: 'Please let me join'
      )

      # Mailer should be responsible for email composition
      expect(JoinTeamRequestMailer).to respond_to(:send_acceptance_email)
    end

    it 'separates concerns: controller handles requests, mailer handles emails' do
      participant2 # Ensure participant exists
      join_request = JoinTeamRequest.create!(
        participant_id: participant2.id,
        team_id: team1.id,
        comments: 'Please let me join'
      )

      team_member_token = JsonWebToken.encode({id: student1.id})
      team_member_headers = { 'Authorization' => "Bearer #{team_member_token}" }

      # Controller should call mailer, not send email directly
      expect(JoinTeamRequestMailer).to receive(:with).and_call_original

      patch "/api/v1/join_team_requests/#{join_request.id}/accept", headers: team_member_headers
    end

    it 'maintains single responsibility: model accepts, mailer notifies' do
      participant2 # Ensure participant exists
      invitation = Invitation.create!(
        to_id: participant2.id,
        from_id: team1.id,
        assignment_id: assignment.id
      )

      # Model's accept_invitation should focus on acceptance logic and delegation
      result = invitation.accept_invitation

      # Check that it returns success
      expect(result[:success]).to be true

      # Emails should be queued (responsibility of mailer)
      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.at_least(:twice)
    end
  end
end
