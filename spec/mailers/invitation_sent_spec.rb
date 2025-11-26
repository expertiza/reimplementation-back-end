require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  include ActiveJob::TestHelper

  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 3, default_page_id: nil) }
  let(:student_role) { Role.create(name: 'Student', parent_id: nil, id: 5, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'instructor@test.com', full_name: 'Test Instructor', password: '123456', role: role) }
  let(:user1) { create :user, name: 'invitee_user', role: student_role, email: 'invitee@test.com' }
  let(:user2) { create :user, name: 'inviter_user', role: student_role, email: 'inviter@test.com' }
  let(:assignment) { create(:assignment, instructor: instructor) }

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  after(:each) do
    clear_enqueued_jobs
  end

  describe '#send_invitation_email' do
    it 'sends invitation email to invitee' do
      invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_invitation_email
      
      expect(email.to).to eq([user1.email])
      expect(email.subject).to include('invitation')
    end
  end

  describe '#send_acceptance_email' do
    it 'sends acceptance email to invitee' do
      invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_acceptance_email
      
      expect(email.to).to eq([user1.email])
      expect(email.subject).to include('accepted')
    end

    it 'includes invitee name in email body' do
      invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_acceptance_email
      
      expect(email.body.encoded).to include(user1.full_name)
    end

    it 'includes team name in email body' do
      team = AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam')
      invitation = Invitation.create(to_id: user1.id, from_id: team.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_acceptance_email
      
      expect(email.body.encoded).to include(team.name)
    end

    it 'includes assignment name in email body' do
      team = AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam')
      invitation = Invitation.create(to_id: user1.id, from_id: team.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_acceptance_email
      
      expect(email.body.encoded).to include(assignment.name)
    end
  end

  describe '#send_team_acceptance_notification' do
    it 'sends notification email to all team members' do
      team = AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam')
      inviter_participant = AssignmentParticipant.create(user_id: user2.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'inviter_handle')
      TeamsParticipant.create(team_id: team.id, participant_id: inviter_participant.id, user_id: user2.id)
      
      invitation = Invitation.create(to_id: user1.id, from_id: team.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_team_acceptance_notification
      
      expect(email.to).to include(user2.email)
    end

    it 'includes invitee name in team notification body' do
      team = AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam')
      inviter_participant = AssignmentParticipant.create(user_id: user2.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'inviter_handle')
      TeamsParticipant.create(team_id: team.id, participant_id: inviter_participant.id, user_id: user2.id)
      
      invitation = Invitation.create(to_id: user1.id, from_id: team.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_team_acceptance_notification
      
      expect(email.body.encoded).to include(user1.full_name)
    end

    it 'includes team name in team notification body' do
      team = AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam')
      inviter_participant = AssignmentParticipant.create(user_id: user2.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'inviter_handle')
      TeamsParticipant.create(team_id: team.id, participant_id: inviter_participant.id, user_id: user2.id)
      
      invitation = Invitation.create(to_id: user1.id, from_id: team.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_team_acceptance_notification
      
      expect(email.body.encoded).to include(team.name)
    end

    it 'includes assignment name in team notification body' do
      team = AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam')
      inviter_participant = AssignmentParticipant.create(user_id: user2.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'inviter_handle')
      TeamsParticipant.create(team_id: team.id, participant_id: inviter_participant.id, user_id: user2.id)
      
      invitation = Invitation.create(to_id: user1.id, from_id: team.id, assignment_id: assignment.id)
      
      email = InvitationMailer.with(invitation: invitation).send_team_acceptance_notification
      
      expect(email.body.encoded).to include(assignment.name)
    end
  end
end
