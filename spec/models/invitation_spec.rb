require 'rails_helper'

RSpec.describe Invitation, type: :model do
  let(:user1) { create :user, name: 'rohitgeddam' }
  let(:user2) { create :user, name: 'superman' }
  let(:invalid_user) { build :user, name: 'INVALID' }
  let(:assignment) { create(:assignment) }


  it 'is invitation_factory returning new Invitation' do
    invitation = Invitation.invitation_factory(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    expect(invitation).to be_valid
  end

  it 'sends an invitation email' do
    invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    expect do
      invitation.send_invite_email
    end.to have_enqueued_job.on_queue('default').exactly(:once)
  end

  it 'accepts invitation and change reply_status to Accept(A)' do
    invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    invitation.accept_invitation(nil)
    expect(invitation.reply_status).to eq(InvitationValidator::ACCEPT_STATUS)
  end

  it 'rejects invitation and change reply_status to Reject(R)' do
    invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    invitation.decline_invitation(nil)
    expect(invitation.reply_status).to eq(InvitationValidator::REJECT_STATUS)
  end

  it 'retracts invitation' do
    invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    invitation.retract_invitation(nil)
    expect { invitation.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'as_json works as expected' do
    invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    expect(invitation.as_json).to include('to_user', 'from_user', 'assignment', 'reply_status', 'id')
  end

  it 'is invited? false' do
    invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    truth = Invitation.invited?(user1.id, user2.id, assignment.id)
    expect(truth).to eq(false)
  end

  it 'is invited? true' do
    invitation = Invitation.create(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    truth = Invitation.invited?(user2.id, user1.id, assignment.id)
    expect(truth).to eq(true)
  end

  it 'is default reply_status set to WAITING' do
    invitation = Invitation.new(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id)
    expect(invitation.reply_status).to eq('W')
  end

  it 'is valid with valid attributes' do
    invitation = Invitation.new(to_id: user1.id, from_id: user2.id, assignment_id: assignment.id,
                                reply_status: InvitationValidator::WAITING_STATUS)
    expect(invitation).to be_valid
  end

  it 'is invalid with same from and to attribute' do
    invitation = Invitation.new(to_id: user1.id, from_id: user1.id, assignment_id: assignment.id,
                                reply_status: InvitationValidator::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid to user attribute' do
    invitation = Invitation.new(to_id: 'INVALID', from_id: user2.id, assignment_id: assignment.id,
                                reply_status: InvitationValidator::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid from user attribute' do
    invitation = Invitation.new(to_id: user1.id, from_id: 'INVALID', assignment_id: assignment.id,
                                reply_status: InvitationValidator::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid assignment attribute' do
    invitation = Invitation.new(to_id: user1.id, from_id: user2.id, assignment_id: 'INVALID',
                                reply_status: InvitationValidator::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid reply_status attribute' do
    invitation = Invitation.new(to_id: user1.id, from_id: user2.id, assignment_id: 'INVALID',
                                reply_status: 'X')
    expect(invitation).to_not be_valid
  end
end
