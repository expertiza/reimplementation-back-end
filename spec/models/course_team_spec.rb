# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CourseTeam, type: :model do
  # --- FactoryBot Setup ---
  let!(:course) { create(:course) }
  let!(:other_course) { create(:course) }
  let!(:assignment) { create(:assignment) }
  let!(:course_team) { create(:course_team, course: course) }
  let!(:participant) { create(:course_participant, course: course) }
  let!(:other_participant) { create(:course_participant, course: other_course) }

  # --- Validation Tests ---
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(course_team).to be_valid
    end

    it 'is not valid without a course' do
      team = build(:course_team, course: nil, parent_id: nil)
      expect(team).not_to be_valid
      # This validation comes from the `belongs_to :course` association
      expect(team.errors[:course]).to include("must exist")
      # This validation comes from the base Team class
      expect(team.errors[:parent_id]).to include("can't be blank")
    end
  end

  # --- Association Tests ---
  describe 'associations' do
    it { should belong_to(:course) }
    it { should have_many(:teams_participants).dependent(:destroy) }
    it { should have_many(:participants).through(:teams_participants) }
    it { should have_many(:users).through(:teams_participants) }
  end

  # --- Polymorphic Method Implementation Tests ---
  describe 'polymorphic methods' do
    it 'returns course as parent_entity' do
      expect(course_team.parent_entity).to eq(course)
    end

    it 'returns CourseParticipant as participant_class' do
      expect(course_team.participant_class).to eq(CourseParticipant)
    end

    it 'returns "course" as context_label' do
      expect(course_team.context_label).to eq('course')
    end

    it 'returns nil for max_team_size (no limit for course teams)' do
      expect(course_team.max_team_size).to be_nil
    end
  end

  # --- Behavior Tests ---
  describe '#add_member' do
    context 'when participant is in the same course' do
      it 'adds the member successfully' do
        expect {
          result = course_team.add_member(participant)
          expect(result[:success]).to be true
        }.to change(TeamsParticipant, :count).by(1)
        expect(course_team.participants).to include(participant)
      end
    end

    context 'when participant is from a different course' do
      it 'does not add the member' do
        expect {
          result = course_team.add_member(other_participant)
          expect(result[:success]).to be false
          expect(result[:error]).to match(/Participant belongs to.*but this team belongs to/)
        }.not_to change(TeamsParticipant, :count)
      end
    end

    context 'when participant is an AssignmentParticipant' do
      it 'does not add the member' do
        wrong_type_participant = create(:assignment_participant, assignment: assignment)
        result = course_team.add_member(wrong_type_participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/Participant belongs to.*Assignment.*but this team belongs to.*Course/)
      end
    end
  end

  describe '#full?' do
    it 'always returns false, even with many members' do
      expect(course_team.full?).to be false

      # Add multiple members
      5.times do
        course_team.add_member(create(:course_participant, course: course))
      end

      # Still not full
      expect(course_team.size).to eq(5)
      expect(course_team.full?).to be false
    end
  end

  # --- Copy Logic Tests ---
  describe '#copy_to_assignment_team' do
    before do
      # Add a member to the original team
      course_team.add_member(participant)
    end

    it 'creates a new AssignmentTeam with copied members' do
      new_team = course_team.copy_to_assignment_team(assignment)

      expect(new_team).to be_an(AssignmentTeam)
      expect(new_team.persisted?).to be true
      expect(new_team.name).to eq(course_team.name) # Name should be identical
      expect(new_team.parent_id).to eq(assignment.id)

      # Check that members were copied
      expect(new_team.participants.count).to eq(1)
      expect(new_team.users.first).to eq(participant.user)
    end
  end

  describe '#copy_to_course_team' do
    before do
      # Add a member to the original team
      course_team.add_member(participant)
    end

    it 'creates a new CourseTeam with copied members' do
      new_team = course_team.copy_to_course_team(other_course)

      expect(new_team).to be_a(CourseTeam)
      expect(new_team.persisted?).to be true
      expect(new_team.name).to eq(course_team.name) # Name should be identical
      expect(new_team.parent_id).to eq(other_course.id)

      # Check that members were copied
      expect(new_team.participants.count).to eq(1)
      expect(new_team.users.first).to eq(participant.user)
    end
  end
end
