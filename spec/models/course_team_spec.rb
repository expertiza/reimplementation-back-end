# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CourseTeam, type: :model do

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

  let(:course_team) do
    CourseTeam.create!(
      parent_id:      course.id,
      name:           'team 2',
    )
  end

  before do
    participant = create(:course_participant, user: team_owner, course: course)
    course_team.add_member(team_owner)
  end


  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(course_team).to be_valid
    end

    it 'is not valid without a course' do
      team = build(:course_team, course: nil)
      expect(team).not_to be_valid
      expect(team.errors[:course]).to include("must exist")
    end

    it 'validates type must be CourseTeam' do
      team = build(:course_team)
      team.type = 'WrongType'
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("must be 'Assignment' or 'Course' or 'Mentor'")
    end
  end

  describe '#add_member' do
    context 'when user is not enrolled in the course' do
      it 'does not add the member to the team' do
        unenrolled_user = create_student("add_user")

        expect {
          course_team.add_member(unenrolled_user)
        }.not_to change(TeamsParticipant, :count)
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:course) }
    it { should have_many(:teams_participants).dependent(:destroy) }
    it { should have_many(:users).through(:teams_participants) }
  end

  describe 'team management' do
    let(:enrolled_user) { create(:user, role: create(:role)) }
    let(:unenrolled_user) { create(:user, role: create(:role)) }

    before do
      @participant = create(:course_participant, user: enrolled_user, course: course)
    end

    it 'can add enrolled user' do
      result = course_team.add_member(enrolled_user)
      
      expect(result[:success]).to be true
      expect(course_team.has_member?(enrolled_user)).to be true
    end

    it 'cannot add unenrolled user' do
      result = course_team.add_member(unenrolled_user)

      expect(result[:success]).to be false
      expect(result[:error]).to eq("#{unenrolled_user.name} is not a participant in this course")
    end
  end
end 
