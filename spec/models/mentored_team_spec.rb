# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  
  include RolesHelper
  # --------------------------------------------------------------------------
  # Global Setup
  # --------------------------------------------------------------------------
  # Create the full roles hierarchy once, to be shared by all examples.
  let!(:roles) { create_roles_hierarchy }

  # ------------------------------------------------------------------------
  # Helper: DRY-up creation of student users with a predictable pattern.
  # ------------------------------------------------------------------------
  def create_student(suffix)
    User.create!(
      name:            suffix,
      email:           "#{suffix}@example.com",
      full_name:       suffix.split('_').map(&:capitalize).join(' '),
      password_digest: "password",
      role_id:          roles[:student].id,
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
      role_id:          roles[:instructor].id,
      institution_id:  institution.id
    )
  end

  let(:team_owner) do
    User.create!(
      name:            "team_owner",
      full_name:       "Team Owner",
      email:           "team_owner@example.com",
      password_digest: "password",
      role_id:          roles[:student].id,
      institution_id:  institution.id
    )
  end

  let!(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  let!(:course)  { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course1") }

  let(:mentor_role) { create(:role, :mentor) }

  let(:mentor) do
    User.create!(
      name: "mentor_user",
      full_name: "Mentor User",
      email: "mentor@example.com",
      password_digest: "password",
      role_id: mentor_role.id,
      institution_id: institution.id
    )
  end

  let(:mentored_team) do
    MentoredTeam.create!(
      parent_id: mentor.id,
      assignment: assignment,
      name: 'team 3',
      user_id: team_owner.id,
      mentor: mentor
    )
  end

  let(:user) do
    User.create!(
      name: "student_user",
      full_name: "Student User",
      email: "student@example.com",
      password_digest: "password",
      role_id: roles[:student].id,
      institution_id: institution.id
    )
  end

  let!(:team) { create(:mentored_team, user: user, assignment: assignment) }


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
    it { should have_many(:teams_participants).dependent(:destroy) }
    it { should have_many(:users).through(:teams_participants) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user) }

    before do
      @participant = create(:assignment_participant, user: enrolled_user, assignment: assignment)
    end

    it 'can add enrolled user' do
      expect(team.add_member(enrolled_user)).to be_truthy
      expect(team.has_member?(enrolled_user)).to be_truthy
    end

    it 'cannot add mentor as member' do
      expect(team.add_member(team.mentor)).to be_falsey
      expect(team.has_member?(team.mentor)).to be_falsey
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
