require 'rails_helper'

RSpec.describe TeamJoinRequest, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:join_request) { build(:team_join_request, team: team, user: user) }

  it 'is valid with valid attributes' do
    expect(join_request).to be_valid
  end

  it 'is not valid without a team' do
    join_request.team = nil
    expect(join_request).not_to be_valid
  end

  it 'is not valid without a user' do
    join_request.user = nil
    expect(join_request).not_to be_valid
  end

  it 'has a default status of pending' do
    expect(join_request.status).to eq('pending')
  end

  it 'can be accepted' do
    join_request.save
    join_request.accept!
    expect(join_request.status).to eq('accepted')
  end

  it 'can be rejected' do
    join_request.save
    join_request.reject!
    expect(join_request.status).to eq('rejected')
  end

  it 'creates a team member when accepted' do
    expect {
      join_request.save
      join_request.accept!
    }.to change(TeamMember, :count).by(1)
  end

  it 'does not create a team member when rejected' do
    expect {
      join_request.save
      join_request.reject!
    }.not_to change(TeamMember, :count)
  end
end 