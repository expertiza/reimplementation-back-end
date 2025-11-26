require 'rails_helper'
require 'swagger_helper'

RSpec.describe Invitation, type: :model do
  include ActiveJob::TestHelper
  before(:all) do
    @roles = create_roles_hierarchy
  end

  let(:instructor) { create(:user, role_id: @roles[:instructor].id, name: "profa", full_name: "Prof A", email: "profa@example.com")}
  let(:user1) do
    User.create!( name: "student", password_digest: "password",role_id: @roles[:student].id, full_name: "Student Name",email: "student@example.com") 
  end

  let(:user2) do
    User.create!(
      name: "student2", password_digest: "password", role_id: @roles[:student].id, full_name: "Student Two", email: "student2@example.com")
  end
  let(:assignment) { Assignment.create!(name: "Test Assignment", instructor_id: instructor.id) }
  let(:team1) { AssignmentTeam.create!(name: "Team1", parent_id: assignment.id) }
  let(:team2) { AssignmentTeam.create!(name: "Team2", parent_id: assignment.id) }

  let(:participant1) { AssignmentParticipant.create!(user: user1, parent_id: assignment.id, handle: 'user1_handle') }
  let(:participant2) { AssignmentParticipant.create!(user: user2, parent_id: assignment.id, handle: 'user2_handle') }
  let(:invalid_user) { build :user, name: 'INVALID' }

  before do
    # assign participants to teams
    team1.add_participant(participant1)
    team2.add_participant(participant2)
  end

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  after(:each) do
    clear_enqueued_jobs
  end


  it 'is invitation_factory returning new Invitation' do
    invitation = Invitation.invitation_factory(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    expect(invitation).to be_valid
  end

  it 'sends an invitation email' do
    invitation = Invitation.create(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    expect do
      invitation.send_invite_email
    end.to have_enqueued_job.on_queue('default').exactly(:once)
  end

  it 'accepts invitation and change reply_status to Accept(A)' do
    invitation = Invitation.create(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    invitation.accept_invitation
    expect(invitation.reply_status).to eq(InvitationValidator::ACCEPT_STATUS)
  end

  it 'accepts invitation and update invitee team' do
    invitation = Invitation.create(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    invitation.accept_invitation
    participant1.reload
    expect(participant1.team_id).to eq(team2.id)
  end

  it 'rejects invitation and change reply_status to Decline(D)' do
    invitation = Invitation.create(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    invitation.decline_invitation
    expect(invitation.reply_status).to eq(InvitationValidator::DECLINED_STATUS)
  end

  it 'retracts invitation' do
    invitation = Invitation.create(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    invitation.retract_invitation
    expect(invitation.reply_status).to eq(InvitationValidator::RETRACT_STATUS)
  end

  it 'as_json works as expected' do
    invitation = Invitation.create(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    expect(invitation.as_json).to include('to_participant', 'from_team', 'assignment', 'reply_status', 'id')
  end

  it 'is invited? false' do
    invitation = Invitation.create(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    truth = Invitation.invited?(participant1.id, team2.id, assignment.id)
    expect(truth).to eq(false)
  end

  it 'is invited? true' do
    invitation = Invitation.create(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    truth = Invitation.invited?(team2.id, participant1.id, assignment.id)
    expect(truth).to eq(true)
  end

  it 'is default reply_status set to WAITING' do
    invitation = Invitation.new(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,  participant_id: participant2.id)
    expect(invitation.reply_status).to eq('W')
  end

  it 'is valid with valid attributes' do
    invitation = Invitation.new(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,
                                reply_status: InvitationValidator::WAITING_STATUS,  participant_id: participant2.id)
    expect(invitation).to be_valid
  end

  it 'is invalid with same from and to attribute' do
    invitation = Invitation.new(to_id: participant1.id, participant_id: participant1.id, assignment_id: assignment.id,
                                reply_status: InvitationValidator::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid to user attribute' do
    invitation = Invitation.new(to_id: 'INVALID', from_id: team2.id, assignment_id: assignment.id,
                                reply_status: InvitationValidator::WAITING_STATUS,  participant_id: participant2.id)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid from user attribute' do
    invitation = Invitation.new(to_id: participant1.id, from_id: 'INVALID', assignment_id: assignment.id,
                                reply_status: InvitationValidator::WAITING_STATUS,  participant_id: participant2.id)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid assignment attribute' do
    invitation = Invitation.new(to_id: participant1.id, from_id: team2.id, assignment_id: 'INVALID',
                                reply_status: InvitationValidator::WAITING_STATUS,  participant_id: participant2.id)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid reply_status attribute' do
    invitation = Invitation.new(to_id: participant1.id, from_id: team2.id, assignment_id: assignment.id,
                                reply_status: 'X',  participant_id: participant2.id)
    expect(invitation).to_not be_valid
  end
end