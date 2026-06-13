# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Team edge cases', type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NC State') }
  let(:instructor)  { User.create!(name: 'inst_e', full_name: 'Instructor', email: 'inst_e@test.com', password_digest: 'x', role_id: @roles[:instructor].id, institution_id: institution.id) }
  let(:assignment)  { Assignment.create!(name: 'Edge Assign', instructor_id: instructor.id, max_team_size: 3) }
  let(:team)        { AssignmentTeam.create!(name: 'Edge Team', parent_id: assignment.id) }

  def make_participant(suffix, assign = assignment)
    user = User.create!(name: suffix, full_name: suffix, email: "#{suffix}@test.com", password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
    AssignmentParticipant.create!(user: user, parent_id: assign.id, handle: user.name)
  end

  # ── already-enrolled member ─────────────────────────────────────────────────
  describe 'adding already-enrolled member' do
    it 'rejects adding the same participant twice to the same team' do
      participant = make_participant('dup1')
      team.add_member(participant)
      result = team.add_member(participant)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/already on the team/)
    end

    it 'rejects adding same user to two teams in the same assignment' do
      team2       = AssignmentTeam.create!(name: 'Edge Team 2', parent_id: assignment.id)
      participant = make_participant('dup2')
      team.add_member(participant)
      result = team2.add_member(participant)
      expect(result[:success]).to be false
    end
  end

  # ── zero members ────────────────────────────────────────────────────────────
  describe 'team with zero members' do
    it 'reports team_size of 0' do
      expect(team.team_size).to eq(0)
    end

    it 'is not full when empty' do
      expect(team.full?).to be false
    end

    it 'destroys team when last member is removed' do
      participant = make_participant('last_one')
      team.add_member(participant)
      team.remove_member(participant)
      expect(Team.exists?(team.id)).to be false
    end

    it 'does not raise error calling remove_mentor on empty MentoredTeam' do
      mentored = MentoredTeam.create!(name: 'Empty Mentored', parent_id: assignment.id)
      Duty.create!(name: 'Mentor', instructor_id: instructor.id)
      expect { mentored.remove_mentor }.not_to raise_error
    end
  end

  # ── no participants in assignment ───────────────────────────────────────────
  describe 'assignment with no participants' do
    let(:empty_assignment) { Assignment.create!(name: 'Empty Assign', instructor_id: instructor.id, max_team_size: 3) }
    let(:empty_team)       { AssignmentTeam.create!(name: 'Empty Team', parent_id: empty_assignment.id) }

    it 'allows creating a team for an assignment with no participants' do
      expect(empty_team).to be_persisted
    end

    it 'rejects adding a user who is not a participant in the assignment' do
      user   = User.create!(name: 'no_part', full_name: 'no_part', email: 'no_part@test.com', password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
      result = empty_team.add_member(user)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/not a participant/)
    end

    it 'rejects a participant from a different assignment' do
      other_assign = Assignment.create!(name: 'Other Assign', instructor_id: instructor.id, max_team_size: 3)
      user         = User.create!(name: 'wrong_assign', full_name: 'wrong_assign', email: 'wrong_assign@test.com', password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
      participant  = AssignmentParticipant.create!(user: user, parent_id: other_assign.id, handle: user.name)
      result       = empty_team.add_member(user)
      expect(result[:success]).to be false
    end
  end
end
