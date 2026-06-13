# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Capacity and size limits', type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NC State') }
  let(:instructor)  { User.create!(name: 'inst_cap', full_name: 'Instructor', email: 'inst_cap@test.com', password_digest: 'x', role_id: @roles[:instructor].id, institution_id: institution.id) }
  let(:assignment)  { Assignment.create!(name: 'Cap Assign', instructor_id: instructor.id, max_team_size: 2) }
  let(:team)        { AssignmentTeam.create!(name: 'Cap Team', parent_id: assignment.id) }

  def make_participant(suffix, assign = assignment)
    user = User.create!(name: suffix, full_name: suffix, email: "#{suffix}@test.com", password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
    AssignmentParticipant.create!(user: user, parent_id: assign.id, handle: user.name)
  end

  describe 'AssignmentTeam capacity' do
    it 'returns false for full? when under capacity' do
      expect(team.full?).to be false
    end

    it 'returns true for full? when at max_team_size' do
      2.times { |i| team.add_member(make_participant("cap#{i}")) }
      team.reload
      expect(team.full?).to be true
    end

    it 'rejects member when team is full' do
      2.times { |i| team.add_member(make_participant("full#{i}")) }
      extra  = make_participant('extra')
      result = team.add_member(extra)
      expect(result[:success]).to be false
      expect(result[:error]).to match(/capacity/)
    end

    it 'returns correct team_size' do
      p1 = make_participant('sz1')
      team.add_member(p1)
      team.reload
      expect(team.team_size).to eq(1)
    end

    it 'returns max_size equal to assignment max_team_size' do
      expect(team.max_size).to eq(2)
    end
  end

  describe 'CourseTeam has no capacity limit' do
    let(:course)       { Course.create!(name: 'Cap Course', instructor_id: instructor.id, institution_id: institution.id, directory_path: '/cap') }
    let(:course_team)  { CourseTeam.create!(name: 'Cap Course Team', parent_id: course.id) }

    it 'always returns false for full?' do
      5.times do |i|
        user = User.create!(name: "ccu#{i}", full_name: "ccu#{i}", email: "ccu#{i}@test.com", password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
        p    = CourseParticipant.create!(user: user, parent_id: course.id, handle: user.name)
        course_team.add_member(p)
      end
      expect(course_team.full?).to be false
    end
  end
end
