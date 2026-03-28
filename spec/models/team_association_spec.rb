# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Association integrity', type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NC State') }
  let(:instructor)  { User.create!(name: 'inst_a', full_name: 'Instructor', email: 'inst_a@test.com', password_digest: 'x', role_id: @roles[:instructor].id, institution_id: institution.id) }
  let(:assignment)  { Assignment.create!(name: 'Assoc Assign', instructor_id: instructor.id, max_team_size: 3) }
  let(:course)      { Course.create!(name: 'Assoc Course', instructor_id: instructor.id, institution_id: institution.id, directory_path: '/assoc') }

  def make_user(suffix)
    User.create!(name: suffix, full_name: suffix, email: "#{suffix}@test.com", password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
  end

  # ── Team is abstract ────────────────────────────────────────────────────────
  describe 'Team as abstract superclass' do
    it 'is invalid with type set directly to Team' do
      team = Team.new(parent_id: assignment.id, name: 'Raw Team', type: 'Team')
      expect(team).not_to be_valid
    end

    it 'is valid as MentoredTeam subclass' do
      team = MentoredTeam.new(parent_id: assignment.id, name: 'MT')
      expect(team).to be_valid
    end
  end

  # ── AssignmentTeam associations ─────────────────────────────────────────────
  describe 'AssignmentTeam' do
    let(:team) { AssignmentTeam.create!(name: 'Assoc AT', parent_id: assignment.id) }

    it 'is linked to the correct assignment via parent_id' do
      expect(team.assignment).to eq(assignment)
    end

    it 'membership records are scoped to this team' do
      user        = make_user('at_user')
      participant = AssignmentParticipant.create!(user: user, parent_id: assignment.id, handle: user.name)
      team.add_member(participant)

      expect(TeamsParticipant.where(team_id: team.id).count).to eq(1)
    end

    it 'participants association returns only members of this team' do
      user1 = make_user('at_u1')
      user2 = make_user('at_u2')
      p1    = AssignmentParticipant.create!(user: user1, parent_id: assignment.id, handle: user1.name)
      p2    = AssignmentParticipant.create!(user: user2, parent_id: assignment.id, handle: user2.name)

      team2 = AssignmentTeam.create!(name: 'Assoc AT2', parent_id: assignment.id)
      team.add_member(p1)
      team2.add_member(p2)

      expect(team.participants).to include(p1)
      expect(team.participants).not_to include(p2)
    end
  end

  # ── CourseTeam associations ─────────────────────────────────────────────────
  describe 'CourseTeam' do
    let(:team) { CourseTeam.create!(name: 'Assoc CT', parent_id: course.id) }

    it 'is linked to the correct course via parent_id' do
      expect(team.course).to eq(course)
    end

    it 'membership records are scoped to this team' do
      user        = make_user('ct_user')
      participant = CourseParticipant.create!(user: user, parent_id: course.id, handle: user.name)
      team.add_member(participant)

      expect(TeamsParticipant.where(team_id: team.id).count).to eq(1)
    end
  end

  # ── MentoredTeam associations ───────────────────────────────────────────────
  describe 'MentoredTeam' do
    let(:team) { MentoredTeam.create!(name: 'Assoc MT', parent_id: assignment.id) }

    it 'is a subclass of AssignmentTeam' do
      expect(team).to be_a(AssignmentTeam)
    end

    it 'is linked to the correct assignment' do
      expect(team.assignment).to eq(assignment)
    end
  end
end
