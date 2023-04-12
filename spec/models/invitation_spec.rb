require 'rails_helper'

RSpec.describe Invitation, type: :model do
  let(:user1) { build(:user, id: 4, name: 'no name', fullname: 'no two') }
  let(:user2) { build(:user, id: 5, name: 'no name 2', fullname: 'no two 2') }
  let(:assignment) { build(:assignment)}

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  it "is valid with valid attributes" do
    invitation = Invitation.new(to_user: user1, from_user: user2, assignment: assignment, reply_status: 'W')
    expect(invitation).to be_valid
  end

  it "is invalid with same from and to attribute" do
    invitation = Invitation.new(to_user: user1, from_user: user1, assignment: assignment, reply_status: 'W')
    expect(invitation).to_not be_valid
  end

  it "is invalid with invalid to user attribute" do
    invitation = Invitation.new(to_user: nil, from_user: user2, assignment: assignment, reply_status: 'W')
    expect(invitation).to_not be_valid
  end

  it "is invalid with invalid from user attribute" do
    invitation = Invitation.new(to_user: user1, from_user: nil, assignment: assignment, reply_status: 'W')
    expect(invitation).to_not be_valid
  end

  it "is invalid with invalid assignment attribute" do
    invitation = Invitation.new(to_user: user1, from_user: user2, assignment: nil, reply_status: 'W')
    expect(invitation).to_not be_valid
  end

  it "is invalid with invalid reply_status attribute" do
    invitation = Invitation.new(to_user: user1, from_user: user2, assignment: assignment, reply_status: 'X')
    expect(invitation).to_not be_valid
  end
end
