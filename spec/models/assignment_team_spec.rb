require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  
  include RolesHelper
  # --------------------------------------------------------------------------
  # Global Setup
  # --------------------------------------------------------------------------
  # Create the full roles hierarchy once, to be shared by all examples.
  before(:all) do
    @roles = create_roles_hierarchy
  end

  # ------------------------------------------------------------------------
  # Helper: DRY-up creation of student users with a predictable pattern.
  # ------------------------------------------------------------------------
  def create_student(suffix)
    User.create!(
      name:            suffix,
      email:           "#{suffix}@example.com",
      full_name:       suffix.split('_').map(&:capitalize).join(' '),
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  # ------------------------------------------------------------------------
  # Shared Data Setup: Build core domain objects used across tests.
  # ------------------------------------------------------------------------
  let(:institution) do
    # All users belong to the same institution to satisfy foreign key constraints.
    Institution.create!(name: "NC State")
  end

  let(:instructor) do
    # The instructor will own assignments and courses in subsequent tests.
    User.create!(
      name:            "instructor",
      full_name:       "Instructor User",
      email:           "instructor@example.com",
      password_digest: "password",
      role_id:          @roles[:instructor].id,
      institution_id:  institution.id
    )
  end

  let(:team_owner) do
    User.create!(
      name:            "team_owner",
      full_name:       "Team Owner",
      email:           "team_owner@example.com",
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  let(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  let(:course)  { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course1") }

  let(:assignment_team) do
    AssignmentTeam.create!(
      parent_id:      assignment.id,
      name:           'team 1',
      user_id:        team_owner.id
    )
  end


  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(assignment_team).to be_valid
    end

    it 'is not valid without an assignment' do
      team = build(:assignment_team, assignment: nil)
      expect(team).not_to be_valid
      expect(team.errors[:assignment]).to include("must exist")
    end

    it 'validates type must be AssignmentTeam' do
      team = build(:assignment_team)
      team.type = 'WrongType'
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("must be 'Assignment' or 'Course'")
    end
  end

  describe '#add_member' do
    context 'when user is not enrolled in the assignment' do
      it 'does not add the member to the team' do
        unenrolled_user = create_student("add_user")

        expect {
          assignment_team.add_member(unenrolled_user)
        }.not_to change(TeamsParticipant, :count)
      end

      it 'returns false' do
        unenrolled_user = create_student("add_user")
        
        result = assignment_team.add_member(unenrolled_user)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("#{unenrolled_user.name} is not a participant in this assignment")
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:assignment) }
    it { should belong_to(:user).optional }
    it { should have_many(:teams_participants).dependent(:destroy) }
    it { should have_many(:users).through(:teams_participants) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user) }
    let(:unenrolled_user) { create(:user) }

    before do
      @participant = create(:assignment_participant, user: enrolled_user, assignment: assignment)
    end

    it 'cannot add unenrolled user' do
      result = assignment_team.add_member(unenrolled_user)

      expect(result[:success]).to be false
      expect(result[:error]).to eq("#{unenrolled_user.name} is not a participant in this assignment")
    end
  end
end 