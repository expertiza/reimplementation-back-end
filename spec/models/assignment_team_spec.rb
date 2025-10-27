# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssignmentTeam, type: :model do
  # --- FactoryBot Setup ---
  let!(:course) { create(:course) }
  let!(:assignment) { create(:assignment, max_team_size: 3) }
  let!(:other_assignment) { create(:assignment) }
  let!(:assignment_team) { create(:assignment_team, assignment: assignment, max_size: 3) }
  let!(:participant) { create(:assignment_participant, assignment: assignment) }
  let!(:other_participant) { create(:assignment_participant, assignment: other_assignment) }

  # --- Validation Tests ---
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(assignment_team).to be_valid
    end

    it 'is not valid without an assignment' do
      team = build(:assignment_team, assignment: nil, parent_id: nil)
      expect(team).not_to be_valid
      # This validation comes from the `belongs_to :assignment` association
      expect(team.errors[:assignment]).to include("must exist")
      # This validation comes from the base Team class
      expect(team.errors[:parent_id]).to include("can't be blank")
    end
  end

  # --- Association Tests ---
  describe 'associations' do
    it { should belong_to(:assignment) }
    it { should have_many(:teams_participants).dependent(:destroy) }
    it { should have_many(:participants).through(:teams_participants) }
    it { should have_many(:users).through(:teams_participants) }
  end

  # --- Polymorphic Method Implementation Tests ---
  describe 'polymorphic methods' do
    it 'returns assignment as parent_entity' do
      expect(assignment_team.parent_entity).to eq(assignment)
    end

    it 'returns AssignmentParticipant as participant_class' do
      expect(assignment_team.participant_class).to eq(AssignmentParticipant)
    end

    it 'returns "assignment" as context_label' do
      expect(assignment_team.context_label).to eq('assignment')
    end

    it 'returns assignment max_team_size' do
      expect(assignment_team.max_team_size).to eq(3)
    end
  end

  # --- Behavior Tests ---
  describe '#add_member' do
    context 'when participant is in the same assignment' do
      it 'adds the member successfully' do
        expect {
          result = assignment_team.add_member(participant)
          expect(result[:success]).to be true
        }.to change(TeamsParticipant, :count).by(1)
        expect(assignment_team.participants).to include(participant)
      end
    end

    context 'when participant is from a different assignment' do
      it 'does not add the member' do
        expect {
          result = assignment_team.add_member(other_participant)
          expect(result[:success]).to be false
          expect(result[:error]).to match(/Participant belongs to.*but this team belongs to/)
        }.not_to change(TeamsParticipant, :count)
      end
    end

    context 'when participant is a CourseParticipant' do
      it 'does not add the member' do
        wrong_type_participant = create(:course_participant, course: course)
        result = assignment_team.add_member(wrong_type_participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/Participant belongs to.*Course.*but this team belongs to.*Assignment/)
      end
    end

    context 'when team is full' do
      it 'rejects new members' do
        # Fill the team to its max size of 3
        3.times do
          assignment_team.add_member(create(:assignment_participant, assignment: assignment))
        end

        expect(assignment_team.full?).to be true

        # Try to add one more
        overflow_participant = create(:assignment_participant, assignment: assignment)
        result = assignment_team.add_member(overflow_participant)

        expect(result[:success]).to be false
        expect(result[:error]).to match(/Team is at full capacity/)
      end
    end
  end

  # --- Copy Logic Tests ---
  describe '#copy_to_course_team' do
    before do
      # Add a member to the original team
      assignment_team.add_member(participant)
    end

    it 'creates a new CourseTeam with copied members' do
      new_team = assignment_team.copy_to_course_team(course)

      expect(new_team).to be_a(CourseTeam)
      expect(new_team.persisted?).to be true
      expect(new_team.name).to eq(assignment_team.name) # Name should be identical
      expect(new_team.parent_id).to eq(course.id)

      # Check that members were copied
      expect(new_team.participants.count).to eq(1)
      expect(new_team.users.first).to eq(participant.user)
    end
  end

  describe '#copy_to_assignment_team' do
    before do
      # Add a member to the original team
      assignment_team.add_member(participant)
    end

    it 'creates a new AssignmentTeam with copied members' do
      new_team = assignment_team.copy_to_assignment_team(other_assignment)

      expect(new_team).to be_an(AssignmentTeam)
      expect(new_team.persisted?).to be true
      expect(new_team.name).to eq(assignment_team.name) # Name should be identical
      expect(new_team.parent_id).to eq(other_assignment.id)

      # Check that members were copied
      expect(new_team.participants.count).to eq(1)
      expect(new_team.users.first).to eq(participant.user)
    end
  end
end
