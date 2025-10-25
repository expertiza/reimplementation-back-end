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
    # Create participant for team_owner and add them to the team
    @owner_participant = create(:course_participant, user: team_owner, course: course)
    course_team.add_member(@owner_participant)
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
      expect(team.errors[:type]).to include("must be 'AssignmentTeam', 'CourseTeam', or 'MentoredTeam'")
    end
  end

  describe 'polymorphic methods' do
    it 'returns course as parent_entity' do
      expect(course_team.parent_entity).to eq(course)
    end

    it 'returns CourseParticipant as participant_class' do
      expect(course_team.participant_class).to eq(CourseParticipant)
    end

    it 'returns course as context_label' do
      expect(course_team.context_label).to eq('course')
    end

    it 'returns nil for max_team_size (no limit for course teams)' do
      expect(course_team.max_team_size).to be_nil
    end
  end

  describe '#add_member' do
    context 'when user is not enrolled in the course' do
      it 'does not add the member to the team' do
        unenrolled_user = create_student("add_user")
        # Create participant for different course
        other_course = Course.create!(
          name: "Other Course",
          instructor_id: instructor.id,
          institution_id: institution.id,
          directory_path: "/other"
        )
        other_participant = CourseParticipant.create!(
          parent_id: other_course.id,
          user: unenrolled_user,
          handle: unenrolled_user.name
        )

        expect {
          course_team.add_member(other_participant)
        }.not_to change(TeamsParticipant, :count)
      end

      it 'returns error hash when participant not registered' do
        unenrolled_user = create_student("add_user_2")
        # Create participant for different course
        other_course = Course.create!(
          name: "Different Course",
          instructor_id: instructor.id,
          institution_id: institution.id,
          directory_path: "/different"
        )
        other_participant = CourseParticipant.create!(
          parent_id: other_course.id,
          user: unenrolled_user,
          handle: unenrolled_user.name
        )

        result = course_team.add_member(other_participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/not a participant in this course/)
      end
    end

    context 'when user is properly enrolled' do
      it 'adds the member successfully' do
        enrolled_user = create_student("enrolled_user")
        participant = CourseParticipant.create!(
          parent_id: course.id,
          user: enrolled_user,
          handle: enrolled_user.name
        )

        expect {
          result = course_team.add_member(participant)
          expect(result[:success]).to be true
        }.to change(TeamsParticipant, :count).by(1)
      end

      it 'returns success hash' do
        enrolled_user = create_student("enrolled_user_2")
        participant = CourseParticipant.create!(
          parent_id: course.id,
          user: enrolled_user,
          handle: enrolled_user.name
        )

        result = course_team.add_member(participant)
        expect(result[:success]).to be true
        expect(result[:error]).to be_nil
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

    it 'can add enrolled user via participant' do
      result = course_team.add_member(@participant)
      
      expect(result[:success]).to be true
      expect(course_team.has_member?(enrolled_user)).to be true
    end

    it 'cannot add unenrolled user' do
      # Create participant for different course
      other_course = Course.create!(
        name: "Another Course",
        instructor_id: instructor.id,
        institution_id: institution.id,
        directory_path: "/another"
      )
      wrong_participant = create(:course_participant, user: unenrolled_user, course: other_course)

      result = course_team.add_member(wrong_participant)

      expect(result[:success]).to be false
      expect(result[:error]).to match(/not a participant in this course/)
    end
  end

  describe '#full?' do
    it 'always returns false (no capacity limit for course teams)' do
      expect(course_team.full?).to be false

      # Add multiple members
      5.times do |i|
        user = create_student("member_#{i}")
        participant = CourseParticipant.create!(
          parent_id: course.id,
          user: user,
          handle: user.name
        )
        course_team.add_member(participant)
      end

      # Still not full
      expect(course_team.full?).to be false
    end
  end

  describe '#copy_to_assignment_team' do
    it 'creates a new AssignmentTeam with copied members' do
      # Add another member to the team
      member = create(:user)
      participant = create(:course_participant, user: member, course: course)
      course_team.add_member(participant)

      # Copy to assignment team
      assignment_team = course_team.copy_to_assignment_team(assignment)

      expect(assignment_team).to be_a(AssignmentTeam)
      expect(assignment_team.name).to include('Assignment')
      expect(assignment_team.parent_id).to eq(assignment.id)
      # Members should be copied (note: copying creates AssignmentParticipants)
      expect(assignment_team.participants.count).to eq(course_team.participants.count)
    end
  end

  describe '#copy_to_course_team' do
    it 'creates a new CourseTeam with copied members' do
      other_course = Course.create!(
        name: "Course 2",
        instructor_id: instructor.id,
        institution_id: institution.id,
        directory_path: "/course2"
      )
      
      # Copy to new course team
      new_team = course_team.copy_to_course_team(other_course)

      expect(new_team).to be_a(CourseTeam)
      expect(new_team.name).to include('Copy')
      expect(new_team.parent_id).to eq(other_course.id)
      expect(new_team.participants.count).to eq(course_team.participants.count)
    end
  end
end
