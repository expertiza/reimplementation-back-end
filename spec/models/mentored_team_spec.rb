# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NC State') }
  let(:instructor)  { User.create!(name: 'inst_m', full_name: 'Instructor', email: 'inst_m@test.com', password_digest: 'x', role_id: @roles[:instructor].id, institution_id: institution.id) }
  let(:assignment)  { Assignment.create!(name: 'Mentored Assign', instructor_id: instructor.id, max_team_size: 5) }
  let(:team)        { MentoredTeam.create!(name: 'Mentored Team 1', parent_id: assignment.id) }
  let(:mentor_duty) { Duty.create!(name: 'Mentor', instructor_id: instructor.id) }

  def make_user(suffix)
    User.create!(name: suffix, full_name: suffix, email: "#{suffix}@test.com", password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
  end

  def make_participant(suffix)
    user = make_user(suffix)
    AssignmentParticipant.create!(user: user, parent_id: assignment.id, handle: user.name)
  end

  # ── Subclass-specific behavior ──────────────────────────────────────────────
  describe '#assign_mentor' do
    it 'sets the mentor duty on the participant' do
      mentor_duty
      participant = make_participant('mentor1')
      team.add_member(participant)

      result = team.assign_mentor(participant.user)
      expect(result).to be true
      expect(participant.reload.duty_id).to eq(mentor_duty.id)
    end

    it 'returns false when Mentor duty does not exist' do
      participant = make_participant('mentor2')
      team.add_member(participant)

      result = team.assign_mentor(participant.user)
      expect(result).to be false
    end

    it 'returns false when user is not a participant in the assignment' do
      mentor_duty
      outsider = make_user('outsider_m')
      result   = team.assign_mentor(outsider)
      expect(result).to be false
    end

    it 'identifies mentor by duty not by role' do
      mentor_duty
      participant = make_participant('duty_mentor')
      team.add_member(participant)
      team.assign_mentor(participant.user)

      expect(team.send(:mentor)).to eq(participant.user)
      expect(participant.reload.duty).to eq(mentor_duty)
    end
  end

  describe '#remove_mentor' do
    it 'clears the duty from the mentor participant' do
      mentor_duty
      participant = make_participant('remove_mentor')
      team.add_member(participant)
      team.assign_mentor(participant.user)

      team.remove_mentor
      expect(participant.reload.duty_id).to be_nil
    end

    it 'does nothing when no mentor is assigned' do
      mentor_duty
      expect { team.remove_mentor }.not_to raise_error
    end
  end

  describe '#add_member' do
    it 'blocks adding the mentor as a regular member' do
      mentor_duty
      participant = make_participant('blocked_mentor')
      team.add_member(participant)
      team.assign_mentor(participant.user)

      result = team.add_member(participant.user)
      expect(result).to be false
    end

    it 'allows adding a non-mentor participant' do
      participant = make_participant('regular_member')
      result      = team.add_member(participant)
      expect(result[:success]).to be true
    end

    it 'inherits capacity limit from AssignmentTeam' do
      small_assignment = Assignment.create!(name: 'Small Assign', instructor_id: instructor.id, max_team_size: 1)
      small_team       = MentoredTeam.create!(name: 'Small Team', parent_id: small_assignment.id)

      user1 = make_user('cap1')
      user2 = make_user('cap2')
      p1    = AssignmentParticipant.create!(user: user1, parent_id: small_assignment.id, handle: user1.name)
      p2    = AssignmentParticipant.create!(user: user2, parent_id: small_assignment.id, handle: user2.name)

      small_team.add_member(p1)
      result = small_team.add_member(p2)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/capacity/)
    end
  end
end
