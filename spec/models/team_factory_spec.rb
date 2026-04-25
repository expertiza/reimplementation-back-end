# frozen_string_literal: true

require 'rails_helper'

# Tests for Team.create_team_for_participant - the factory used by the
# Calibration tab (and elsewhere) to create the team that backs an individual
# submitter.
RSpec.describe Team, type: :model do
  include RolesHelper

  before(:all) { @roles = create_roles_hierarchy }

  let(:institution) { Institution.create!(name: 'NC State') }

  def create_student(suffix)
    User.create!(
      name: suffix,
      email: "#{suffix}@example.com",
      full_name: suffix.titleize,
      password_digest: 'password',
      role_id: @roles[:student].id,
      institution_id: institution.id
    )
  end

  let(:instructor) do
    User.create!(
      name: 'calibration_instructor_factory',
      full_name: 'Calibration Instructor',
      email: 'calibration_instructor_factory@example.com',
      password_digest: 'password',
      role_id: @roles[:instructor].id,
      institution_id: institution.id
    )
  end

  let(:assignment) { Assignment.create!(name: 'Calibration A', instructor_id: instructor.id, max_team_size: 1) }
  let(:course)     { Course.create!(name: 'Course C', instructor_id: instructor.id, institution_id: institution.id, directory_path: '/c1') }

  describe '.create_team_for_participant' do
    context 'for an AssignmentParticipant' do
      it 'creates an AssignmentTeam whose parent is the assignment' do
        user = create_student('calib_sub1')
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)

        team = Team.create_team_for_participant(participant)

        expect(team).to be_a(AssignmentTeam)
        expect(team.parent_id).to eq(assignment.id)
        expect(team.participants).to include(participant)
      end

      it 'generates a stable, unique name when none is provided' do
        user1 = create_student('calib_sub_a')
        user2 = create_student('calib_sub_b')
        p1 = AssignmentParticipant.create!(parent_id: assignment.id, user: user1, handle: user1.name)
        p2 = AssignmentParticipant.create!(parent_id: assignment.id, user: user2, handle: user2.name)

        t1 = Team.create_team_for_participant(p1)
        t2 = Team.create_team_for_participant(p2)

        expect(t1.name).to include(user1.name)
        expect(t2.name).to include(user2.name)
        expect(t1.name).not_to eq(t2.name)
      end
    end

    context 'for a CourseParticipant' do
      it 'creates a CourseTeam whose parent is the course' do
        user = create_student('course_sub1')
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)

        team = Team.create_team_for_participant(participant)

        expect(team).to be_a(CourseTeam)
        expect(team.parent_id).to eq(course.id)
        expect(team.participants).to include(participant)
      end
    end

    it 'raises on nil participant' do
      expect { Team.create_team_for_participant(nil) }.to raise_error(ArgumentError)
    end

    it 'raises on an unsupported participant type' do
      fake = Object.new
      expect { Team.create_team_for_participant(fake) }.to raise_error(ArgumentError, /Unsupported/)
    end
  end
end
