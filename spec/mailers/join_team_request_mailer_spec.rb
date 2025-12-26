require "rails_helper"

RSpec.describe JoinTeamRequestMailer, type: :mailer do
  include ActiveJob::TestHelper

  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 3, default_page_id: nil) }
  let(:student_role) { Role.create(name: 'Student', parent_id: nil, id: 5, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'instructor@test.com', full_name: 'Test Instructor', password: '123456', role: role) }
  let(:requester) { create :user, name: 'requester_user', role: student_role, email: 'requester@test.com' }
  let(:team_member) { create :user, name: 'team_member_user', role: student_role, email: 'team_member@test.com' }
  let(:assignment) { create(:assignment, instructor: instructor) }
  let(:team) { AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam') }
  let(:requester_participant) { AssignmentParticipant.create(user_id: requester.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'requester_handle') }
  let(:team_member_participant) { AssignmentParticipant.create(user_id: team_member.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'team_member_handle') }
  let(:join_team_request) { JoinTeamRequest.create(participant_id: requester_participant.id, team_id: team.id, comments: 'Please let me join', reply_status: 'PENDING') }

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    TeamsParticipant.create(team_id: team.id, participant_id: team_member_participant.id, user_id: team_member.id)
  end

  after(:each) do
    clear_enqueued_jobs
  end

  describe '#send_acceptance_email' do
    it 'sends acceptance email to requester' do
      email = JoinTeamRequestMailer.with(join_team_request: join_team_request).send_acceptance_email
      
      expect(email.to).to eq([requester.email])
    end

    it 'has correct subject line' do
      email = JoinTeamRequestMailer.with(join_team_request: join_team_request).send_acceptance_email
      
      expect(email.subject).to include('accepted')
    end

    it 'includes requester name in email body' do
      email = JoinTeamRequestMailer.with(join_team_request: join_team_request).send_acceptance_email
      
      expect(email.body.encoded).to include(requester.full_name)
    end

    it 'includes team name in email body' do
      email = JoinTeamRequestMailer.with(join_team_request: join_team_request).send_acceptance_email
      
      expect(email.body.encoded).to include(team.name)
    end

    it 'includes assignment name in email body' do
      email = JoinTeamRequestMailer.with(join_team_request: join_team_request).send_acceptance_email
      
      expect(email.body.encoded).to include(assignment.name)
    end

    it 'includes congratulatory message in email body' do
      email = JoinTeamRequestMailer.with(join_team_request: join_team_request).send_acceptance_email
      
      expect(email.body.encoded).to include('Good news')
    end

    it 'includes collaboration message in email body' do
      email = JoinTeamRequestMailer.with(join_team_request: join_team_request).send_acceptance_email
      
      expect(email.body.encoded).to include('collaborate')
    end
  end
end
