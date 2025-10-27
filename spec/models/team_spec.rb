# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Team, type: :model do
  let!(:course) { create(:course) }
  let!(:assignment) { create(:assignment, max_team_size: 3) }

  # Create one team for each context using factories
  let!(:course_team) { create(:course_team, course: course) }
  let!(:assignment_team) { create(:assignment_team, assignment: assignment, max_size: 3) }

  # ------------------------------------------------------------------------
  # Validation Tests
  # ------------------------------------------------------------------------
  describe 'validations' do
    it 'is invalid without parent_id' do
      team = build(:assignment_team, parent_id: nil)
      expect(team).not_to be_valid
      expect(team.errors[:parent_id]).to include("can't be blank")
    end

    it 'is invalid without type' do
      team = build(:assignment_team, type: nil)
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("can't be blank")
    end

    it 'is invalid with incorrect type' do
      team = build(:assignment_team, type: 'InvalidTeamType')
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("must be 'AssignmentTeam', 'CourseTeam', or 'MentoredTeam'")
    end

    it 'is valid as AssignmentTeam' do
      # We must create the parent to get a valid parent_id
      assignment = create(:assignment)
      expect(build(:assignment_team, assignment: assignment, parent_id: assignment.id)).to be_valid
    end

    it 'is valid as CourseTeam' do
      # We must create the parent to get a valid parent_id
      course = create(:course)
      expect(build(:course_team, course: course, parent_id: course.id)).to be_valid
    end
  end

  # ------------------------------------------------------------------------
  # Tests for polymorphic abstract methods
  # ------------------------------------------------------------------------
  describe 'abstract methods' do

    it 'implements parent_entity for AssignmentTeam' do
      expect(assignment_team.parent_entity).to eq(assignment)
    end

    it 'implements parent_entity for CourseTeam' do
      expect(course_team.parent_entity).to eq(course)
    end

    it 'implements participant_class for AssignmentTeam' do
      expect(assignment_team.participant_class).to eq(AssignmentParticipant)
    end

    it 'implements participant_class for CourseTeam' do
      expect(course_team.participant_class).to eq(CourseParticipant)
    end

    it 'implements context_label for AssignmentTeam' do
      expect(assignment_team.context_label).to eq('assignment')
    end

    it 'implements context_label for CourseTeam' do
      expect(course_team.context_label).to eq('course')
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #full?
  # ------------------------------------------------------------------------
  describe '#full?' do
    it 'returns true when participants count >= assignment.max_team_size' do
      # Fill the team up to its max size (3)
      3.times do
        participant = create(:assignment_participant, assignment: assignment)
        assignment_team.add_member(participant)
      end

      expect(assignment_team.participants.count).to eq(3)
      expect(assignment_team.full?).to be true
    end

    it 'returns false when participants count < assignment.max_team_size' do
      expect(assignment_team.full?).to be false
    end

    it 'always returns false for a CourseTeam (no capacity limit)' do
      # Add more participants than the assignment team's limit
      5.times do
        participant = create(:course_participant, course: course)
        course_team.add_member(participant)
      end

      expect(course_team.full?).to be false
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #can_participant_join_team?
  # ------------------------------------------------------------------------
  describe '#can_participant_join_team?' do
    context 'AssignmentTeam context' do
      let!(:participant) { create(:assignment_participant, assignment: assignment) }

      it 'rejects a participant already on a team' do
        assignment_team.add_member(participant) # Add to this team

        # Create a second team in the same assignment
        other_team = create(:assignment_team, assignment: assignment)
        result = other_team.can_participant_join_team?(participant)

        expect(result[:success]).to be false
        expect(result[:error]).to match(/already assigned/)
      end
    end

    context 'CourseTeam context' do
      let!(:participant) { create(:course_participant, course: course) }

      it 'rejects a participant already on a course team' do
        course_team.add_member(participant) # Add to this team

        # Create a second team in the same course
        other_team = create(:course_team, course: course)
        result = other_team.can_participant_join_team?(participant)

        expect(result[:success]).to be false
        expect(result[:error]).to match(/already assigned/)
      end
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #add_member
  # ------------------------------------------------------------------------
  describe '#add_member' do
    context 'AssignmentTeam' do
      let!(:participant) { create(:assignment_participant, assignment: assignment) }

      it 'creates a TeamsParticipant record on success' do
        expect {
          result = assignment_team.add_member(participant)
          expect(result[:success]).to be true
        }.to change { TeamsParticipant.where(team_id: assignment_team.id).count }.by(1)
      end

      it 'returns an error if the assignment team is already full' do
        # Fill up to assignment.max_team_size (3)
        3.times do
          p = create(:assignment_participant, assignment: assignment)
          assignment_team.add_member(p)
        end

        extra_participant = create(:assignment_participant, assignment: assignment)
        result = assignment_team.add_member(extra_participant)

        expect(result[:success]).to be false
        expect(result[:error]).to include("Team is at full capacity")
      end

      it 'validates participant type matches team type' do
        # Create a CourseParticipant
        wrong_participant = create(:course_participant, course: course)

        result = assignment_team.add_member(wrong_participant)
        expect(result[:success]).to be false

        expect(result[:error]).to match(/Participant belongs to.*Course.*but this team belongs to.*Assignment/)
      end
    end

    context 'CourseTeam' do
      let!(:participant) { create(:course_participant, course: course) }

      it 'creates a TeamsParticipant record on success' do
        expect {
          result = course_team.add_member(participant)
          expect(result[:success]).to be true
        }.to change { TeamsParticipant.where(team_id: course_team.id).count }.by(1)
      end

      it 'still adds even if team is "full" (CourseTeam#full? is always false)' do
        # Add a few members
        create(:course_participant, course: course).tap { |p| course_team.add_member(p) }
        create(:course_participant, course: course).tap { |p| course_team.add_member(p) }

        # Add one more
        result = course_team.add_member(participant)

        # CourseTeam.full? is always false, so add_member should succeed
        expect(result[:success]).to be true
        expect(course_team.size).to eq(3)
      end

      it 'validates participant type matches team type' do
        # Create an AssignmentParticipant
        wrong_participant = create(:assignment_participant, assignment: assignment)

        result = course_team.add_member(wrong_participant)
        expect(result[:success]).to be false
        
        expect(result[:error]).to match(/Participant belongs to.*Assignment.*but this team belongs to.*Course/)
      end
    end
  end

  # ------------------------------------------------------------------------
  # Tests for helper methods
  # ------------------------------------------------------------------------
  describe '#size' do
    it 'returns the number of participants' do
      expect(assignment_team.size).to eq(0)

      participant = create(:assignment_participant, assignment: assignment)
      assignment_team.add_member(participant)

      expect(assignment_team.size).to eq(1)
    end
  end

  describe '#empty?' do
    it 'returns true when no participants' do
      expect(assignment_team.empty?).to be true
    end

    it 'returns false when participants exist' do
      participant = create(:assignment_participant, assignment: assignment)
      assignment_team.add_member(participant)

      expect(assignment_team.empty?).to be false
    end
  end
end
