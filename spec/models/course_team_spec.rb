require 'rails_helper'

RSpec.describe CourseTeam, type: :model do
  let(:user) { create(:user, role: create(:role)) }
  let(:course) { create(:course) }
  let(:assignment) { create(:assignment, course: course) }
  let(:course_team) { create(:course_team, course: course) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(course_team).to be_valid
    end

    it 'is not valid without a course' do
      team = build(:course_team, course: nil)
      expect(team).not_to be_valid
      expect(team.errors[:course]).to include("can't be blank")
    end

    it 'validates type must be CourseTeam' do
      team = build(:course_team)
      team.type = 'WrongType'
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include('must be CourseTeam')
    end
  end

  describe '#add_member' do
    context 'when user is not enrolled in the course' do
      it 'does not add the member to the team' do
        expect {
          course_team.add_member(user)
        }.not_to change(TeamMember, :count)
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:course) }
    it { should belong_to(:user).optional }
    it { should have_many(:team_members).dependent(:destroy) }
    it { should have_many(:users).through(:team_members) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user, role: create(:role)) }
    let(:unenrolled_user) { create(:user, role: create(:role)) }

    before do
      create(:participant, user: enrolled_user, assignment: assignment)
    end

    it 'can add enrolled user' do
      expect(course_team.add_member(enrolled_user)).to be_truthy
      expect(course_team.member?(enrolled_user)).to be_truthy
    end

    it 'cannot add unenrolled user' do
      expect(course_team.add_member(unenrolled_user)).to be_falsey
      expect(course_team.member?(unenrolled_user)).to be_falsey
    end
  end
end 