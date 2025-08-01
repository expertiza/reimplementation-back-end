require 'rails_helper'

# This spec exercises the Team model, covering:
#  - Presence and inclusion validations on parent_id and STI type
#  - The full? method, which determines if a team has reached capacity
#  - The can_participant_join_team? method, which enforces eligibility rules
#  - The add_member method, which creates TeamsParticipant records
RSpec.describe Team, type: :model do
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

  # Two assignments with explicit max_team_size values, for testing AssignmentTeam.full?
  let(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  let(:assignment2) { Assignment.create!(name: "Assignment 2", instructor_id: instructor.id, max_team_size: 2) }

  # Two courses (Course model does not have max_team_size column)
  let(:course)  { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course1") }
  let(:course2) { Course.create!(name: "Course 2", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course2") }

  # ------------------------------------------------------------------------
  # Create one team per context using STI subclasses
  # ------------------------------------------------------------------------
  let(:assignment_team) do
    AssignmentTeam.create!(
      parent_id:      assignment.id,
      name:           'team 1',
      user_id:        team_owner.id
    )
  end

  let(:course_team) do
    CourseTeam.create!(
      parent_id:      course.id,
      name:           'team 2',
      user_id:        team_owner.id
    )
  end

  # ------------------------------------------------------------------------
  # Validation Tests
  #
  # Ensure presence of parent_id and type, and correct inclusion for STI.
  # ------------------------------------------------------------------------
  describe 'validations' do
    it 'is invalid without parent_id' do
      # Missing parent_id should trigger a blank error on the parent_id column.
      team = Team.new(type: 'AssignmentTeam')
      expect(team).not_to be_valid
      expect(team.errors[:parent_id]).to include("can't be blank")
    end

    it 'is invalid without type' do
      # Missing STI type should trigger a blank error on the type column.
      team = Team.new(parent_id: assignment.id)
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("can't be blank")
    end

    it 'is invalid with incorrect type' do
      # An unsupported value for type should trigger an inclusion error.
      team = Team.new(parent_id: assignment.id, type: 'Team')
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("must be 'Assignment' or 'Course'")
    end

    it 'is valid as AssignmentTeam' do
      # Correct STI subclass automatically sets type = 'AssignmentTeam'
      expect(assignment_team).to be_valid
    end

    it 'is valid as CourseTeam' do
      # Correct STI subclass automatically sets type = 'CourseTeam'
      expect(course_team).to be_valid
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #full?
  #
  # AssignmentTeam: compares participants.count to assignment.max_team_size.
  # CourseTeam: always returns false (no cap).
  # ------------------------------------------------------------------------
  describe '#full?' do
    it 'returns true when participants count >= assignment.max_team_size' do
      # Seed exactly max_team_size participants into the assignment_team.
      3.times do |i|
        user        = create_student("student#{i}")
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        assignment_team.id,
          user_id:        user.id
        )
      end

      assignment_team.reload
      expect(assignment_team.participants.count).to eq(3)
      expect(assignment_team.full?).to be true
    end

    it 'returns false when participants count < assignment.max_team_size' do
      # No participants seeded; count is 0 < 3.
      expect(assignment_team.full?).to be false
    end

    it 'always returns false for a CourseTeam (no capacity limit)' do
      # Seed multiple participants into the course_team.
      5.times do |i|
        user        = create_student("cstudent#{i}")
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        course_team.id,
          user_id:        user.id
        )
      end

      course_team.reload
      expect(course_team.full?).to be false
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #can_participant_join_team?
  #
  # Ensures a participant:
  #  - Cannot join if already on any team in the same context
  #  - Cannot join if not registered in that assignment/course
  #  - Can join otherwise
  # ------------------------------------------------------------------------
  describe '#can_participant_join_team?' do
    context 'AssignmentTeam context' do
      it 'rejects a participant already on a team' do
        user        = create_student("student_team")
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        assignment_team.id,
          user_id:        user.id
        )

        result = assignment_team.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/already assigned/)
      end

      it 'rejects a participant registered under a different assignment' do
        user        = create_student("wrong_assignment")
        participant = AssignmentParticipant.create!(parent_id: assignment2.id, user: user, handle: user.name)

        result = assignment_team.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/not a participant/)
      end

      it 'allows a properly registered, not-yet-teamed participant' do
        user        = create_student("eligible")
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)

        result = assignment_team.can_participant_join_team?(participant)
        expect(result[:success]).to be true
      end
    end

    context 'CourseTeam context' do
      it 'rejects a participant already on a course team' do
        user        = create_student("course_user")
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        course_team.id,
          user_id:        user.id
        )

        result = course_team.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/already assigned/)
      end

      it 'rejects a participant registered under a different course' do
        user        = create_student("wrong_course")
        participant = CourseParticipant.create!(parent_id: course2.id, user: user, handle: user.name)

        result = course_team.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/not a participant/)
      end

      it 'allows a properly registered, not-yet-teamed course participant' do
        user        = create_student("c_eligible")
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)

        result = course_team.can_participant_join_team?(participant)
        expect(result[:success]).to be true
      end
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #add_member
  #
  # AssignmentTeam:
  #   - Should create a TeamsParticipant record when capacity allows
  #   - Should return an error when at capacity
  # CourseTeam:
  #   - Should always add (unless manually overridden, but model does not cap)
  # ------------------------------------------------------------------------
  describe '#add_member' do
    context 'AssignmentTeam' do
      it 'creates a TeamsParticipant record on success' do
        user        = create_student("add_user")
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)

        expect {
          assignment_team.add_member(participant)
        }.to change { TeamsParticipant.where(team_id: assignment_team.id).count }.by(1)
      end

      it 'returns an error if the assignment team is already full' do
        # Fill up to assignment.max_team_size (3)
        3.times do |i|
          user_i   = create_student("f#{i}")
          part_i   = AssignmentParticipant.create!(parent_id: assignment.id, user: user_i, handle: user_i.name)
          assignment_team.add_member(part_i)
        end

        extra_user = create_student("f_extra")
        extra_part = AssignmentParticipant.create!(parent_id: assignment.id, user: extra_user, handle: extra_user.name)
        result     = assignment_team.add_member(extra_part)

        expect(result[:error]).to include("team is at full capacity")
      end
    end

    context 'CourseTeam' do
      it 'creates a TeamsParticipant record on success' do
        user        = create_student("cadd")
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)
        
        expect {
          course_team.add_member(participant)
        }.to change { TeamsParticipant.where(team_id: course_team.id).count }.by(1)
      end

      it 'still adds even if max_participants is manually set (no cap by default)' do
        # override max_participants, but full? remains false
        course_team.max_participants = 1

        first_user = create_student("cf1")
        first_part = CourseParticipant.create!(parent_id: course.id, user: first_user, handle: first_user.name)
        course_team.add_member(first_part)

        second_user = create_student("cf2")
        second_part = CourseParticipant.create!(parent_id: course.id, user: second_user, handle: second_user.name)
        result      = course_team.add_member(second_part)

        # CourseTeam.full? is false, so add_member should succeed
        expect(result[:success]).to be true
      end
    end
  end
end
