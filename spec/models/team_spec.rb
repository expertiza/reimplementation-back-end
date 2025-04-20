require 'rails_helper'

RSpec.describe Team, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team, type: 'CourseTeam', user: user) }

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:type) }
    it { should validate_presence_of(:max_team_size) }
    it { should validate_numericality_of(:max_team_size).is_greater_than(0) }
    it { should validate_inclusion_of(:type).in_array(%w[CourseTeam AssignmentTeam MentoredTeam]) }
  end

  describe 'associations' do
    it { should belong_to(:user).optional }
    it { should have_many(:team_members).dependent(:destroy) }
    it { should have_many(:users).through(:team_members) }
    it { should have_many(:team_join_requests).dependent(:destroy) }
  end

  describe 'team management' do
    let(:other_user) { create(:user) }

    it 'can add a member' do
      expect(team.add_member(other_user)).to be_truthy
      expect(team.member?(other_user)).to be_truthy
    end

    it 'cannot add the same member twice' do
      team.add_member(other_user)
      expect(team.add_member(other_user)).to be_falsey
    end

    it 'cannot add members when team is full' do
      team.max_team_size = 1
      team.add_member(other_user)
      new_user = create(:user)
      expect(team.add_member(new_user)).to be_falsey
    end

    it 'can remove a member' do
      team.add_member(other_user)
      expect(team.remove_member(other_user)).to be_truthy
      expect(team.member?(other_user)).to be_falsey
    end

    it 'can check if team is empty' do
      expect(team.empty?).to be_truthy
      team.add_member(other_user)
      expect(team.empty?).to be_falsey
    end

    it 'can check if team is full' do
      team.max_team_size = 1
      expect(team.full?).to be_falsey
      team.add_member(other_user)
      expect(team.full?).to be_truthy
    end

    it 'can get team size' do
      expect(team.team_size).to eq(0)
      team.add_member(other_user)
      expect(team.team_size).to eq(1)
    end
  end
end 