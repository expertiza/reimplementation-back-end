require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:assignment) { create(:assignment, course: course) }
  let(:assignment_team) { create(:assignment_team, :with_assignment, assignment: assignment) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(assignment_team).to be_valid
    end

    it 'is not valid without an assignment' do
      team = build(:assignment_team, assignment: nil)
      expect(team).not_to be_valid
      expect(team.errors[:assignment]).to include("can't be blank")
    end

    it 'validates type must be AssignmentTeam' do
      team = build(:assignment_team)
      team.type = 'WrongType'
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include('must be AssignmentTeam or MentoredTeam')
    end
  end

  describe '#add_member' do
    context 'when user is not enrolled in the assignment' do
      it 'does not add the member to the team' do
        expect {
          assignment_team.add_member(user)
        }.not_to change(TeamMember, :count)
      end

      it 'returns false' do
        expect(assignment_team.add_member(user)).to be false
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:assignment) }
    it { should belong_to(:user).optional }
    it { should have_many(:team_members).dependent(:destroy) }
    it { should have_many(:users).through(:team_members) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user) }
    let(:unenrolled_user) { create(:user) }

    before do
      @participant = create(:participant, user: enrolled_user, assignment: assignment)
      puts "Created participant: #{@participant.inspect}"
      puts "Assignment participants: #{assignment.participants.to_a.inspect}"
    end

    it 'cannot add unenrolled user' do
      expect(assignment_team.add_member(unenrolled_user)).to be_falsey
      expect(assignment_team.member?(unenrolled_user)).to be_falsey
    end
  end
end 