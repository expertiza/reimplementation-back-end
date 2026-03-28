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
    it 'prevents same participant from joining two different teams' do
      team2 = AssignmentTeam.create!(name: 'Team V2', parent_id: assignment.id)
      TeamsParticipant.create!(team: team, participant: participant, user: user)

      tp2 = TeamsParticipant.new(team: team2, participant: participant, user: user)
      expect(tp2).not_to be_valid
      expect(tp2.errors[:participant_id]).to be_present
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
