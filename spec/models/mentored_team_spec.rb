require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:assignment) { create(:assignment, course: course) }
  let(:mentor_role) { create(:role, :mentor) }
  let(:team) { create(:mentored_team, user: user, assignment: assignment) }

  describe 'validations' do
    it { should validate_presence_of(:mentor) }
    it { should validate_presence_of(:type) }
    
    it 'requires type to be MentoredTeam' do
      team.type = 'AssignmentTeam'
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include('must be MentoredTeam')
    end

    it 'requires mentor to have mentor role' do
      non_mentor = create(:user)
      team.mentor = non_mentor
      expect(team).not_to be_valid
      expect(team.errors[:mentor]).to include('must have mentor role')
    end
  end

  describe 'associations' do
    it { should belong_to(:mentor).class_name('User') }
    it { should belong_to(:assignment) }
    it { should belong_to(:user).optional }
    it { should have_many(:team_members).dependent(:destroy) }
    it { should have_many(:users).through(:team_members) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user) }

    before do
      create(:participant, user: enrolled_user, assignment: assignment)
    end

    it 'can add enrolled user' do
      expect(team.add_member(enrolled_user)).to be_truthy
      expect(team.member?(enrolled_user)).to be_truthy
    end

    it 'cannot add mentor as member' do
      expect(team.add_member(team.mentor)).to be_falsey
      expect(team.member?(team.mentor)).to be_falsey
    end

    it 'can assign new mentor' do
      new_mentor = create(:user, role: mentor_role)
      expect(team.assign_mentor(new_mentor)).to be_truthy
      expect(team.mentor).to eq(new_mentor)
    end

    it 'cannot assign non-mentor as mentor' do
      non_mentor = create(:user)
      expect(team.assign_mentor(non_mentor)).to be_falsey
      expect(team.mentor).not_to eq(non_mentor)
    end
  end
end 