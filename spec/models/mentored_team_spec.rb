# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  # --- FactoryBot Setup ---
  # The :mentored_team factory automatically uses the :with_mentor_duty trait,
  # ensuring the assignment has a mentor duty available.
  let!(:assignment) { create(:assignment, max_team_size: 2) }
  let!(:team) { create(:mentored_team, assignment: assignment) }
  let!(:mentor_user) { create(:user) }
  let!(:regular_user) { create(:user) }
  let!(:mentor_duty) { Duty.find_by(name: 'mentor') || create(:duty, name: 'mentor', instructor: assignment.instructor) }

  # A participant with the mentor duty
  let!(:mentor_participant) do
    create(:assignment_participant, :with_mentor_duty, user: mentor_user, assignment: assignment)
  end

  # A regular participant without any duty
  let!(:regular_participant) do
    create(:assignment_participant, user: regular_user, assignment: assignment)
  end

  # --- Validation Tests ---
  describe 'validations' do
    it 'is valid on :create without a mentor' do
      # The factory creates a team with no mentor by default
      expect(team).to be_valid
      expect(team.mentor).to be_nil
    end

    it 'is invalid on :update if no mentor is present' do
      # 1. Assign a mentor to make the team valid
      team.assign_mentor(mentor_user)
      expect(team.update(name: 'A New Name')).to be true

      # 2. Remove the mentor
      team.remove_mentor
      expect(team.mentor).to be_nil

      # 3. Try to update again. This should trigger the :update validation
      expect(team.update(name: 'A Second New Name')).to be false
      expect(team.errors[:base]).to include('a mentor must be present')
    end
  end

  # --- Mentor Management API Tests ---
  describe '#assign_mentor' do
    it 'successfully assigns a user as a mentor' do
      result = team.assign_mentor(mentor_user)

      expect(result[:success]).to be true

      expect(team.reload.mentor).to eq(mentor_user)
    end

    it 'finds and promotes an existing participant to mentor' do
      # 'regular_user' is already a participant, but without a duty
      team.add_member(regular_participant)
      expect(regular_participant.duty).to be_nil

      # Now, assign them as mentor
      result = team.assign_mentor(regular_user)
      expect(result[:success]).to be true
      expect(regular_participant.reload.duty).to eq(mentor_duty)
      
      # Reload the team object to get fresh association
      expect(team.reload.mentor).to eq(regular_user)
    end

    it 'returns an error if no mentor duty exists on the assignment' do
      # Create an assignment_team and set type.
      # This avoids the :mentored_team factory and its :with_mentor_duty trait.
      assignment_no_duty = create(:assignment)
      team_no_duty = create(:assignment_team, assignment: assignment_no_duty, type: 'MentoredTeam')
      
      result = team_no_duty.assign_mentor(mentor_user)
      
      expect(result[:success]).to be false
      expect(result[:error]).to match(/No mentor duty found/)
    end
  end

  describe '#remove_mentor' do
    before do
      team.assign_mentor(mentor_user)
    end

    it 'removes the mentor duty from the participant' do
      # Get the participant via the user
      mentor_participant = team.participants.find_by(user_id: mentor_user.id)
      expect(mentor_participant).to be_present

      result = team.remove_mentor
      
      expect(result[:success]).to be true
      expect(mentor_participant.reload.duty).to be_nil
      expect(team.mentor).to be_nil
    end

    it 'returns an error if no mentor is on the team' do
      # Remove the mentor first
      team.remove_mentor
      
      # Try to remove again
      result = team.remove_mentor
      expect(result[:success]).to be false
      expect(result[:error]).to match(/No mentor found/)
    end
  end

  # --- LSP Refactor Tests ---
  describe '#add_member' do
    it 'adds a regular participant successfully' do
      result = team.add_member(regular_participant)
      
      expect(result[:success]).to be true
      expect(team.participants).to include(regular_participant)
    end

    it 'rejects a participant who has a mentor duty' do
      # This tests our 'validate_participant_for_add' hook
      result = team.add_member(mentor_participant)
      
      expect(result[:success]).to be false
      expect(result[:error]).to match(/Mentors cannot be added as regular members/)
    end
  end

  describe '#full?' do
    it 'does not count the mentor toward team capacity' do
      # Assignment max_team_size is 2
      
      # 1. Add a mentor
      team.assign_mentor(mentor_user)
      expect(team.size).to eq(1)
      expect(team.full?).to be false

      # 2. Add first regular member
      team.add_member(regular_participant)
      expect(team.size).to eq(2)
      expect(team.full?).to be false

      # 3. Add second regular member (team is now at capacity)
      team.add_member(create(:assignment_participant, assignment: assignment))
      expect(team.size).to eq(3)
      expect(team.full?).to be true # 1 mentor + 2 members = full
    end

    it 'is full when regular members reach max_team_size' do
      # Assignment max_team_size is 2
      team.add_member(regular_participant)
      team.add_member(create(:assignment_participant, assignment: assignment))
      
      expect(team.size).to eq(2)
      expect(team.full?).to be true
    end
  end

  # --- Getter Method Tests ---
  describe '#mentor' do
    it 'returns the mentor user when one is assigned' do
      team.assign_mentor(mentor_user)
      expect(team.mentor).to eq(mentor_user)
    end

    it 'returns nil when no mentor is assigned' do
      expect(team.mentor).to be_nil
    end
  end
end
