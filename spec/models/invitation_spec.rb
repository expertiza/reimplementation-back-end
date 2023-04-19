require 'rails_helper'

RSpec.describe Invitation, type: :model do
  let(:user1) { create :user, name: 'rohitgeddam' }
  let(:user2) { create :user, name: 'superman' }
  let(:invalid_user) { build :user, name: 'INVALID' }
  let(:assignment) { create(:assignment) }

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
                                reply_status: Invitation::WAITING_STATUS)
    expect(invitation).to be_valid
  end

  it 'is invalid with same from and to attribute' do
    invitation = Invitation.new(to_id: user1.id, from_id: user1.id, assignment_id: assignment.id,
                                reply_status: Invitation::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid to user attribute' do
    invitation = Invitation.new(to_id: 'INVALID', from_id: user2.id, assignment_id: assignment.id,
                                reply_status: Invitation::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid from user attribute' do
    invitation = Invitation.new(to_id: user1.id, from_id: 'INVALID', assignment_id: assignment.id,
                                reply_status: Invitation::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid assignment attribute' do
    invitation = Invitation.new(to_id: user1.id, from_id: user2.id, assignment_id: 'INVALID',
                                reply_status: Invitation::WAITING_STATUS)
    expect(invitation).to_not be_valid
  end

  it 'is invalid with invalid reply_status attribute' do
    invitation = Invitation.new(to_id: user1.id, from_id: user2.id, assignment_id: 'INVALID',
                                reply_status: 'X')
    expect(invitation).to_not be_valid
  end
end
