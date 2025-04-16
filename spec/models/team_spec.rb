require 'rails_helper'

RSpec.describe Team, type: :model do
  # ------------------------------------------------------------------------
  # Global Setup: Create role hierarchy used across all test cases.
  # ------------------------------------------------------------------------
  before(:all) do
    @instructor_role = Role.find_or_create_by!(name: "Instructor")
    @ta_role = Role.find_or_create_by!(name: "Teaching Assistant", parent_id: @instructor_role.id)
    @student_role = Role.find_or_create_by!(name: "Student", parent_id: @ta_role.id)
  end

  # ------------------------------------------------------------------------
  # Shared data setup for institution, instructor, assignments, and courses
  # ------------------------------------------------------------------------
  let(:institution) { Institution.create!(name: "NC State") }

  let(:instructor) do
    User.create!(
      name: "instructor",
      full_name: "Instructor User",
      email: "instructor@example.com",
      password_digest: "password",
      role_id: @instructor_role.id,
      institution_id: institution.id
    )
  end

  let(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id) }
  let(:assignment2) { Assignment.create!(name: "Assignment 2", instructor_id: instructor.id) }

  let(:course)  { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course1") }
  let(:course2) { Course.create!(name: "Course 2", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course2") }

  let(:team_for_assignment) { Team.create!(assignment: assignment) }
  let(:team_for_course)     { Team.create!(course: course) }

  # ------------------------------------------------------------------------
  # Validation tests for assignment_id and course_id presence constraints.
  # ------------------------------------------------------------------------
  describe 'validations' do
    it 'is invalid without assignment_id or course_id' do
      team = Team.new
      expect(team.valid?).to be false
      expect(team.errors[:base]).to include("Team must belong to either an assignment or a course")
    end

    it 'is invalid with both assignment_id and course_id' do
      team = Team.new(assignment: assignment, course: course)
      expect(team.valid?).to be false
      expect(team.errors[:base]).to include("Team cannot be both AssignmentTeam and a CourseTeam")
    end

    it 'is valid with only assignment_id' do
      expect(team_for_assignment).to be_valid
    end

    it 'is valid with only course_id' do
      expect(team_for_course).to be_valid
    end
  end

  # ------------------------------------------------------------------------
  # Tests for the #full? method that checks participant capacity.
  # ------------------------------------------------------------------------
  describe '#full?' do
    # Scenario: Team is at full capacity (3 members), expect full? to return true
    it 'returns true if participant count >= max_participants' do
      team_for_assignment.max_participants = 3

      3.times do |i|
        user = User.create!(
          name: "student#{i}",
          email: "student#{i}@example.com",
          password_digest: "password",
          role_id: @student_role.id,
          full_name: "Student #{i}",
          institution_id: institution.id
        )
        participant = Participant.create!(user: user, assignment: assignment)
        TeamsParticipant.create!(participant_id: participant.id, team_id: team_for_assignment.id, user_id: user.id)
      end

      team_for_assignment.reload  # Ensure latest participant count from DB
      expect(team_for_assignment.participants.count).to eq(3) # Sanity check
      expect(team_for_assignment.full?).to be true
    end

    # Scenario: Team is not full yet (less than max participants)
    it 'returns false if participant count < max_participants' do
      team_for_assignment.max_participants = 5
      expect(team_for_assignment.full?).to be false
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #can_participant_join_team? method across both team types
  # ------------------------------------------------------------------------
  describe '#can_participant_join_team?' do
    context 'AssignmentTeam with AssignmentParticipant' do
      # Participant already in a team — should not be allowed again
      it 'returns error if participant already in a team' do
        user = User.create!(name: "student_team", email: "s1@example.com", full_name: "S1", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        participant = Participant.create!(user: user, assignment: assignment)
        TeamsParticipant.create!(participant_id: participant.id, team_id: team_for_assignment.id, user_id: user.id)
        assignment.reload

        result = team_for_assignment.can_participant_join_team?(participant)
        expect(result[:success]).to be false
      end

      # Participant belongs to a different assignment — should not be eligible
      it 'returns error if participant not in correct assignment' do
        user = User.create!(name: "wrong_assignment", email: "wrong@example.com", full_name: "Wrong", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        participant = Participant.create!(user: user, assignment: assignment2)

        result = team_for_assignment.can_participant_join_team?(participant)
        expect(result[:success]).to be false
      end
    end

    context 'CourseTeam with CourseParticipant' do
      # Participant already in a course team — should be rejected
      it 'returns error if participant already in a team' do
        user = User.create!(name: "course_user", email: "course@example.com", full_name: "Course User", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        participant = Participant.create!(user: user, course: course)
        TeamsParticipant.create!(participant_id: participant.id, team_id: team_for_course.id, user_id: user.id)
        course.reload

        result = team_for_course.can_participant_join_team?(participant)
        expect(result[:success]).to be false
      end

      # Participant belongs to a different course — should be ineligible
      it 'returns error if participant not in correct course' do
        user = User.create!(name: "wrong_course", email: "wrongc@example.com", full_name: "Wrong Course", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        participant = Participant.create!(user: user, course: course2)

        result = team_for_course.can_participant_join_team?(participant)
        expect(result[:success]).to be false
      end
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #add_member method for adding participants to teams
  # ------------------------------------------------------------------------
  describe '#add_member' do
    context 'AssignmentTeam' do
      # Successfully adds participant to assignment team
      it 'adds the participant successfully' do
        user = User.create!(name: "add_user", email: "add@example.com", full_name: "Add", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        participant = Participant.create!(user: user, assignment: assignment)
        expect {
          team_for_assignment.add_member(participant)
        }.to change { TeamsParticipant.where(team_id: team_for_assignment.id).count }.by(1)
      end

      # Prevents adding participant if team is at full capacity
      it 'returns error if team is full' do
        team_for_assignment.max_participants = 1
        user1 = User.create!(name: "f1", email: "f1@example.com", full_name: "F1", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        p1 = Participant.create!(user: user1, assignment: assignment)
        team_for_assignment.add_member(p1)

        user2 = User.create!(name: "f2", email: "f2@example.com", full_name: "F2", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        p2 = Participant.create!(user: user2, assignment: assignment)
        team_for_assignment.max_participants = 1  # Re-assign to avoid attr_accessor reset
        result = team_for_assignment.add_member(p2)
        expect(result[:error]).to include("team is at full capacity")
      end
    end

    context 'CourseTeam' do
      # Successfully adds participant to course team
      it 'adds the participant successfully' do
        user = User.create!(name: "cadd", email: "cadd@example.com", full_name: "C Add", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        participant = Participant.create!(user: user, course: course)
        expect {
          team_for_course.add_member(participant)
        }.to change { TeamsParticipant.where(team_id: team_for_course.id).count }.by(1)
      end

      # Prevents addition if course team is full
      it 'returns error if team is full' do
        team_for_course.max_participants = 1
        user1 = User.create!(name: "cf1", email: "cf1@example.com", full_name: "CF1", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        p1 = Participant.create!(user: user1, course: course)
        team_for_course.add_member(p1)

        user2 = User.create!(name: "cf2", email: "cf2@example.com", full_name: "CF2", password_digest: "password", role_id: @student_role.id, institution_id: institution.id)
        p2 = Participant.create!(user: user2, course: course)
        team_for_course.max_participants = 1  # Re-set to avoid accidental reset
        result = team_for_course.add_member(p2)
        expect(result[:error]).to include("team is at full capacity")
      end
    end
  end
end
