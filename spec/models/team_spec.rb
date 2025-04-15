
require 'rails_helper'

RSpec.describe Team, type: :model do
  # Create a base institution and roles required for associations
  let(:institution) { Institution.create!(name: "NC State") }

  # Create an instructor for assignment and course associations
  let(:instructor) do
    User.create!(
      name: "instructor",
      password_digest: "password",
      full_name: "Instructor Name",
      email: "instructor@example.com",
      role_id: Role.find_or_create_by!(name: "Instructor").id,
      institution_id: institution.id
    )
  end

  # Assignment and Course records for respective team types
  let(:assignment) { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id) }
  let(:assignment2) { Assignment.create!(name: "Assignment 2", instructor_id: instructor.id) }
  let(:course) { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/path") }
  let(:course2) { Course.create!(name: "Course 2", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/path2") }

  # Assignment and Course Teams
  let(:team_for_assignment) { Team.create!(assignment: assignment) }
  let(:team_for_course) { Team.create!(course: course) }

  # A generic student user used across all test cases
  let(:student) do
    User.create!(
      name: "student1",
      password_digest: "password",
      full_name: "Student User",
      email: "student1@example.com",
      role_id: Role.find_or_create_by!(name: "Student").id,
      institution_id: institution.id
    )
  end

  describe 'validations' do
    # Ensures a team must belong to either assignment or course
    it 'is invalid without assignment_id or course_id' do
      team = Team.new
      expect(team.valid?).to be false
      expect(team.errors[:base]).to include("Team must belong to either an assignment or a course")
    end

    # Ensures a team cannot belong to both assignment and course
    it 'is invalid with both assignment_id and course_id' do
      team = Team.new(assignment: assignment, course: course)
      expect(team.valid?).to be false
      expect(team.errors[:base]).to include("Team cannot be both AssignmentTeam and a CourseTeam")
    end

    # Valid team with assignment only
    it 'is valid with only assignment_id' do
      expect(team_for_assignment).to be_valid
    end

    # Valid team with course only
    it 'is valid with only course_id' do
      expect(team_for_course).to be_valid
    end
  end

  describe '#full?' do
    # Simulates a full team when participant count reaches max
    it 'returns true if participant count >= max_participants' do
      3.times do
        team_for_assignment.participants << Participant.create!(user: student.dup, assignment: assignment)
      end
      team_for_assignment.max_participants = 3
      expect(team_for_assignment.full?).to be true
    end

    # Simulates a team with room for more participants
    it 'returns false if participant count < max_participants' do
      team_for_assignment.max_participants = 3
      expect(team_for_assignment.full?).to be false
    end
  end

  describe '#can_participant_join_team?' do
    context 'AssignmentTeam with AssignmentParticipant' do
      let!(:participant) { Participant.create!(user: student, assignment: assignment) }

      # Success: eligible participant can join
      it 'returns success if participant is eligible' do
        result = team_for_assignment.can_participant_join_team?(participant)
        expect(result[:success]).to be true
      end

      # Failure: participant already in team
      it 'returns error if participant already in a team' do
        team_for_assignment.add_member(participant)
        result = team_for_assignment.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/already assigned to a team/)
      end

      # Failure: participant not registered for the assignment
      it 'returns error if participant not in correct assignment' do
        wrong_participant = Participant.create!(user: student, assignment: assignment2)
        result = team_for_assignment.can_participant_join_team?(wrong_participant)
        expect(result[:success]).to be false
        expect(result[:error]).to include("not a participant in this assignment")
      end
    end

    context 'CourseTeam with CourseParticipant' do
      let!(:participant) { Participant.create!(user: student, course: course) }

      # Success: eligible participant can join
      it 'returns success if participant is eligible' do
        result = team_for_course.can_participant_join_team?(participant)
        expect(result[:success]).to be true
      end

      # Failure: participant already on another course team
      it 'returns error if participant already in a team' do
        team_for_course.add_member(participant)
        result = team_for_course.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/already assigned to a team/)
      end

      # Failure: participant not registered in the correct course
      it 'returns error if participant not in correct course' do
        wrong_participant = Participant.create!(user: student, course: course2)
        result = team_for_course.can_participant_join_team?(wrong_participant)
        expect(result[:success]).to be false
        expect(result[:error]).to include("not a participant in this course")
      end
    end
  end

  describe '#add_member' do
    context 'AssignmentTeam' do
      let!(:participant) { Participant.create!(user: student, assignment: assignment) }

      # Success: add member when valid
      it 'adds the participant successfully' do
        expect {
          team_for_assignment.add_member(participant)
        }.to change { team_for_assignment.participants.count }.by(1)
      end

      # Failure: duplicate addition
      it 'returns error if participant already in team' do
        team_for_assignment.add_member(participant)
        result = team_for_assignment.add_member(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to include("already a member")
      end

      # Failure: team full
      it 'returns error if team is full' do
        team_for_assignment.max_participants = 1
        team_for_assignment.add_member(participant)
        another = Participant.create!(user: student.dup, assignment: assignment)
        result = team_for_assignment.add_member(another)
        expect(result[:success]).to be false
        expect(result[:error]).to include("team is at full capacity")
      end
    end

    context 'CourseTeam' do
      let!(:participant) { Participant.create!(user: student, course: course) }

      # Success: valid addition
      it 'adds the participant successfully' do
        expect {
          team_for_course.add_member(participant)
        }.to change { team_for_course.participants.count }.by(1)
      end

      # Failure: already in team
      it 'returns error if participant already in team' do
        team_for_course.add_member(participant)
        result = team_for_course.add_member(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to include("already a member")
      end

      # Failure: course team is full
      it 'returns error if team is full' do
        team_for_course.max_participants = 1
        team_for_course.add_member(participant)
        another = Participant.create!(user: student.dup, course: course)
        result = team_for_course.add_member(another)
        expect(result[:success]).to be false
        expect(result[:error]).to include("team is at full capacity")
      end
    end
  end
end
