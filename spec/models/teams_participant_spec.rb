require 'rails_helper'

RSpec.describe TeamsParticipant, type: :model do
  include RolesHelper

  # --------------------------------------------------------------------------
  # Global Setup
  # --------------------------------------------------------------------------
  before(:all) do
    @roles = create_roles_hierarchy
  end

  # ------------------------------------------------------------------------
  # Helper: DRY-up creation of student users
  # ------------------------------------------------------------------------
  def create_student(suffix)
    User.create!(
      name:            suffix,
      email:           "#{suffix}@example.com",
      full_name:       suffix.split('_').map(&:capitalize).join(' '),
      password_digest: "password",
      role_id:         @roles[:student].id,
      institution_id:  institution.id
    )
  end

  # ------------------------------------------------------------------------
  # Shared Data Setup
  # ------------------------------------------------------------------------
  let(:institution) do
    Institution.create!(name: "NC State")
  end

  let(:instructor) do
    User.create!(
      name:            "instructor",
      full_name:       "Instructor User",
      email:           "instructor@example.com",
      password_digest: "password",
      role_id:         @roles[:instructor].id,
      institution_id:  institution.id
    )
  end

  let(:student_user) { create_student("student1") }
  let(:another_student) { create_student("student2") }

  let(:assignment) { Assignment.create!(name: "Test Assignment", instructor_id: instructor.id, max_team_size: 3) }
  
  let(:team) do
    AssignmentTeam.create!(
      parent_id: assignment.id,
      name:      'Test Team'
    )
  end

  let(:another_team) do
    AssignmentTeam.create!(
      parent_id: assignment.id,
      name:      'Another Team'
    )
  end

  let(:participant) do
    AssignmentParticipant.create!(
      user_id:   student_user.id,
      parent_id: assignment.id,
      handle:    'student1_handle'
    )
  end

  let(:another_participant) do
    AssignmentParticipant.create!(
      user_id:   another_student.id,
      parent_id: assignment.id,
      handle:    'student2_handle'
    )
  end

  # --------------------------------------------------------------------------
  # Association Tests
  # --------------------------------------------------------------------------
  describe 'associations' do
    it { should belong_to(:participant) }
    it { should belong_to(:team) }
    it { should belong_to(:user) }
  end

  # --------------------------------------------------------------------------
  # Validation Tests
  # --------------------------------------------------------------------------
  describe 'validations' do
    it 'is valid with valid attributes' do
      teams_participant = TeamsParticipant.new(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )
      expect(teams_participant).to be_valid
    end

    it 'requires user_id' do
      teams_participant = TeamsParticipant.new(
        participant_id: participant.id,
        team_id:        team.id
      )
      expect(teams_participant).not_to be_valid
      expect(teams_participant.errors[:user_id]).to include("can't be blank")
    end

    it 'enforces uniqueness of participant_id scoped to team_id' do
      TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )

      duplicate = TeamsParticipant.new(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:participant_id]).to include("has already been taken")
    end

    it 'allows same participant in different teams' do
      # Note: This tests the model validation only - business logic may prevent this
      TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )

      different_team_membership = TeamsParticipant.new(
        participant_id: participant.id,
        team_id:        another_team.id,
        user_id:        student_user.id
      )

      # The model allows this, but business logic in controllers should prevent it
      expect(different_team_membership).to be_valid
    end
  end

  # --------------------------------------------------------------------------
  # Creation and Destruction Tests
  # --------------------------------------------------------------------------
  describe 'creation' do
    it 'creates a teams_participant record successfully' do
      expect {
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        team.id,
          user_id:        student_user.id
        )
      }.to change(TeamsParticipant, :count).by(1)
    end

    it 'associates participant with the correct team' do
      teams_participant = TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )

      expect(teams_participant.team).to eq(team)
      expect(teams_participant.participant).to eq(participant)
      expect(teams_participant.user).to eq(student_user)
    end
  end

  describe 'destruction' do
    it 'removes the teams_participant record' do
      teams_participant = TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )

      expect {
        teams_participant.destroy
      }.to change(TeamsParticipant, :count).by(-1)
    end

    it 'does not destroy the associated team or participant' do
      teams_participant = TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )

      team_id = team.id
      participant_id = participant.id

      teams_participant.destroy

      expect(Team.find_by(id: team_id)).not_to be_nil
      expect(Participant.find_by(id: participant_id)).not_to be_nil
    end
  end

  # --------------------------------------------------------------------------
  # Team Membership Transfer Tests (for join team requests)
  # --------------------------------------------------------------------------
  describe 'team membership transfer' do
    it 'allows removing participant from old team and adding to new team' do
      # Create initial membership
      old_membership = TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )

      # Transfer to new team (simulating accept join team request)
      old_membership.destroy

      new_membership = TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        another_team.id,
        user_id:        student_user.id
      )

      expect(new_membership).to be_persisted
      expect(TeamsParticipant.find_by(participant_id: participant.id, team_id: team.id)).to be_nil
      expect(TeamsParticipant.find_by(participant_id: participant.id, team_id: another_team.id)).not_to be_nil
    end

    it 'updates team participant count correctly after transfer' do
      # Add participant to first team
      TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )

      # Add another participant to second team
      TeamsParticipant.create!(
        participant_id: another_participant.id,
        team_id:        another_team.id,
        user_id:        another_student.id
      )

      expect(team.participants.count).to eq(1)
      expect(another_team.participants.count).to eq(1)

      # Transfer first participant to second team
      TeamsParticipant.find_by(participant_id: participant.id, team_id: team.id).destroy
      TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        another_team.id,
        user_id:        student_user.id
      )

      team.reload
      another_team.reload

      expect(team.participants.count).to eq(0)
      expect(another_team.participants.count).to eq(2)
    end
  end

  # --------------------------------------------------------------------------
  # Query Tests
  # --------------------------------------------------------------------------
  describe 'querying' do
    before do
      TeamsParticipant.create!(
        participant_id: participant.id,
        team_id:        team.id,
        user_id:        student_user.id
      )
      TeamsParticipant.create!(
        participant_id: another_participant.id,
        team_id:        another_team.id,
        user_id:        another_student.id
      )
    end

    it 'finds teams_participant by participant_id' do
      result = TeamsParticipant.find_by(participant_id: participant.id)
      expect(result).not_to be_nil
      expect(result.team_id).to eq(team.id)
    end

    it 'finds teams_participant by team_id' do
      result = TeamsParticipant.where(team_id: team.id)
      expect(result.count).to eq(1)
      expect(result.first.participant_id).to eq(participant.id)
    end

    it 'finds all participants for a team through association' do
      expect(team.participants).to include(participant)
      expect(another_team.participants).to include(another_participant)
    end
  end
end
