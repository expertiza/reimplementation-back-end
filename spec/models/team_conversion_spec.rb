# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subclass conversion behavior', type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NC State') }
  let(:instructor)  { User.create!(name: 'inst_c', full_name: 'Instructor', email: 'inst_c@test.com', password_digest: 'x', role_id: @roles[:instructor].id, institution_id: institution.id) }
  let(:course)      { Course.create!(name: 'Course Conv', instructor_id: instructor.id, institution_id: institution.id, directory_path: '/conv') }
  let(:assignment)  { Assignment.create!(name: 'Assign Conv', instructor_id: instructor.id, max_team_size: 5) }

  def make_user(suffix)
    User.create!(name: suffix, full_name: suffix, email: "#{suffix}@test.com", password_digest: 'x', role_id: @roles[:student].id, institution_id: institution.id)
  end

  # ── CourseTeam → AssignmentTeam ─────────────────────────────────────────────
  describe 'CourseTeam#copy_to_assignment_team' do
    let(:course_team) { CourseTeam.create!(name: 'Course Team Conv', parent_id: course.id) }

    it 'creates a new AssignmentTeam' do
      result = course_team.copy_to_assignment_team(assignment)
      expect(result).to be_a(AssignmentTeam)
    end

    it 'appends (Assignment) to the name' do
      result = course_team.copy_to_assignment_team(assignment)
      expect(result.name).to include('(Assignment)')
    end

    it 'associates the new team with the given assignment' do
      result = course_team.copy_to_assignment_team(assignment)
      expect(result.parent_id).to eq(assignment.id)
    end

    it 'copies members to the new assignment team' do
      user        = make_user('conv_user1')
      participant = CourseParticipant.create!(user: user, parent_id: course.id, handle: user.name)
      course_team.add_member(participant)

      a_participant = AssignmentParticipant.create!(user: user, parent_id: assignment.id, handle: user.name)
      result        = course_team.copy_to_assignment_team(assignment)

      expect(result.users).to include(user)
    end
  end

  # ── AssignmentTeam → CourseTeam ─────────────────────────────────────────────
  describe 'AssignmentTeam#copy_to_course_team' do
    let(:assignment_team) { AssignmentTeam.create!(name: 'Assign Team Conv', parent_id: assignment.id) }

    it 'creates a new CourseTeam' do
      result = assignment_team.copy_to_course_team(course)
      expect(result).to be_a(CourseTeam)
    end

    it 'appends (Course) to the name' do
      result = assignment_team.copy_to_course_team(course)
      expect(result.name).to include('(Course)')
    end

    it 'associates the new team with the given course' do
      result = assignment_team.copy_to_course_team(course)
      expect(result.parent_id).to eq(course.id)
    end

    it 'copies members to the new course team' do
      user          = make_user('conv_user2')
      a_participant = AssignmentParticipant.create!(user: user, parent_id: assignment.id, handle: user.name)
      assignment_team.add_member(a_participant)

      c_participant = CourseParticipant.create!(user: user, parent_id: course.id, handle: user.name)
      result        = assignment_team.copy_to_course_team(course)

      expect(result.users).to include(user)
    end
  end
end
