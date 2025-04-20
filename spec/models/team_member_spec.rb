require 'rails_helper'

RSpec.describe TeamMember, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:team_member) { build(:team_member, team: team, user: user) }

  it 'is valid with valid attributes' do
    expect(team_member).to be_valid
  end

  it 'is not valid without a team' do
    team_member.team = nil
    expect(team_member).not_to be_valid
  end

  it 'is not valid without a user' do
    team_member.user = nil
    expect(team_member).not_to be_valid
  end

  it 'has a default role of member' do
    expect(team_member.role).to eq('member')
  end

  it 'can be promoted to admin' do
    team_member.save
    team_member.promote_to_admin!
    expect(team_member.role).to eq('admin')
  end

  it 'can be demoted to member' do
    team_member.save
    team_member.promote_to_admin!
    team_member.demote_to_member!
    expect(team_member.role).to eq('member')
  end

  it 'cannot have duplicate user-team combinations' do
    team_member.save
    duplicate = build(:team_member, team: team, user: user)
    expect(duplicate).not_to be_valid
  end
end 