# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TeamsParticipant, type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NC State') }
  let(:instructor)  { User.create!(name: 'inst', full_name: 'Instructor', email: 'inst@test.com', password_digest: 'x', role_id: @roles[:instructor].id, institution_id: institution.id) }
  let(:assignment)  { Assignment.create!(name: 'Assign 1', instructor_id: instructor.id, max_team_size: 3) }
  let(:course)      { Course.create!(name: 'Course 1', instructor_id: instructor.id, institution_id: institution.id, directory_path: '/c1') }

  def make_user(suffix)
    User.create!(name: suffix, full_name: suffix, email: "#{suffix}@test.com", password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
  end

  # ── 1. Model Validations ────────────────────────────────────────────────────
  describe 'validations' do
    let(:user)        { make_user('v_user') }
    let(:participant) { AssignmentParticipant.create!(user: user, parent_id: assignment.id, handle: user.name) }
    let(:team)        { AssignmentTeam.create!(name: 'Team V', parent_id: assignment.id) }

    it 'is valid with all required fields' do
      tp = TeamsParticipant.new(team: team, participant: participant, user: user)
      expect(tp).to be_valid
    end

    it 'is invalid without user_id' do
      tp = TeamsParticipant.new(team: team, participant: participant)
      expect(tp).not_to be_valid
      expect(tp.errors[:user_id]).to be_present
    end

    it 'is invalid without participant_id' do
      tp = TeamsParticipant.new(team: team, user: user)
      expect(tp).not_to be_valid
    end

    it 'is invalid without team_id' do
      tp = TeamsParticipant.new(participant: participant, user: user)
      expect(tp).not_to be_valid
    end

    # ── uniqueness constraint (our Step 2 change) ──
    it 'prevents same participant from joining two different teams via add_member' do
      team2 = AssignmentTeam.create!(name: 'Team V2', parent_id: assignment.id)
      TeamsParticipant.create!(team: team, participant: participant, user: user)

      result = team2.add_member(participant)
      expect(result[:success]).to be false
    end

    it 'allows same participant on the same team only once' do
      TeamsParticipant.create!(team: team, participant: participant, user: user)
      tp2 = TeamsParticipant.new(team: team, participant: participant, user: user)
      expect(tp2).not_to be_valid
    end

    it 'allows different participants on the same team' do
      user2        = make_user('v_user2')
      participant2 = AssignmentParticipant.create!(user: user2, parent_id: assignment.id, handle: user2.name)
      TeamsParticipant.create!(team: team, participant: participant, user: user)

      tp2 = TeamsParticipant.new(team: team, participant: participant2, user: user2)
      expect(tp2).to be_valid
    end
  end
  # Verifies TeamsParticipant (join table) cannot bypass team capacity; creation must fail once AssignmentTeam reaches assignment.max_team_size.
    describe 'capacity validation (team_not_full)' do
    it 'is invalid when team is already at capacity' do
      assignment.update!(max_team_size: 1)
      team = AssignmentTeam.create!(name: 'Cap Team', parent_id: assignment.id)

      u1 = make_user('cap_u1')
      p1 = AssignmentParticipant.create!(user: u1, parent_id: assignment.id, handle: u1.name)
      TeamsParticipant.create!(team: team, participant: p1, user: u1)

      u2 = make_user('cap_u2')
      p2 = AssignmentParticipant.create!(user: u2, parent_id: assignment.id, handle: u2.name)
      tp2 = TeamsParticipant.new(team: team, participant: p2, user: u2)

      expect(tp2).not_to be_valid
      expect(tp2.errors.full_messages.join(', ')).to match(/full capacity/i)
    end

    it 'raises when creating beyond capacity' do
      assignment.update!(max_team_size: 1)
      team = AssignmentTeam.create!(name: 'Cap Team2', parent_id: assignment.id)

      u1 = make_user('cap2_u1')
      p1 = AssignmentParticipant.create!(user: u1, parent_id: assignment.id, handle: u1.name)
      TeamsParticipant.create!(team: team, participant: p1, user: u1)

      u2 = make_user('cap2_u2')
      p2 = AssignmentParticipant.create!(user: u2, parent_id: assignment.id, handle: u2.name)

      expect {
        TeamsParticipant.create!(team: team, participant: p2, user: u2)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end


  # ── 2. Enrollment-based membership rules ───────────────────────────────────
  describe 'enrollment-based membership via Team#add_member' do
    let(:team) { AssignmentTeam.create!(name: 'Enroll Team', parent_id: assignment.id) }

    it 'rejects a user not enrolled in the assignment' do
      outsider = make_user('outsider')
      result   = team.add_member(outsider)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/not a participant/)
    end

    it 'accepts a user enrolled in the assignment' do
      user        = make_user('enrolled')
      participant = AssignmentParticipant.create!(user: user, parent_id: assignment.id, handle: user.name)
      result      = team.add_member(participant)
      expect(result[:success]).to be true
    end

    it 'rejects a user not enrolled in the assignment when passed as user object' do
      outsider = make_user('not_enrolled')
      result   = team.add_member(outsider)
      expect(result[:success]).to be false
    end
  end
end
