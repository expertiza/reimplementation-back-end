# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RevisionRequest, type: :model do
  include RolesHelper

  let!(:roles) { create_roles_hierarchy }
  let!(:institution) { Institution.create!(name: 'NC State') }
  let!(:instructor) do
    User.create!(
      name: 'instructor1',
      email: 'instructor1@example.com',
      password: 'password',
      full_name: 'Instructor One',
      institution: institution,
      role: roles[:instructor]
    )
  end
  let!(:student) do
    User.create!(
      name: 'student1',
      email: 'student1@example.com',
      password: 'password',
      full_name: 'Student One',
      institution: institution,
      role: roles[:student]
    )
  end
  let!(:course) do
    Course.create!(
      name: 'CSC 517',
      directory_path: 'csc517',
      institution: institution,
      instructor: instructor
    )
  end
  let!(:assignment) do
    Assignment.create!(
      name: 'Assignment One',
      instructor: instructor,
      course: course,
      directory_path: 'assignment_one'
    )
  end
  let!(:participant) do
    AssignmentParticipant.create!(
      user: student,
      assignment: assignment,
      handle: student.name
    )
  end
  let!(:team) { AssignmentTeam.create!(name: 'Team Alpha', parent_id: assignment.id) }
  let!(:membership) { TeamsParticipant.create!(team: team, participant: participant, user: student) }

  describe 'validations' do
    it 'requires comments' do
      revision_request = described_class.new(
        participant: participant,
        team: team,
        assignment: assignment,
        comments: ''
      )

      expect(revision_request).not_to be_valid
      expect(revision_request.errors[:comments]).to include("can't be blank")
    end

    it 'allows only one pending request per participant and team' do
      described_class.create!(
        participant: participant,
        team: team,
        assignment: assignment,
        comments: 'First request'
      )

      duplicate = described_class.new(
        participant: participant,
        team: team,
        assignment: assignment,
        comments: 'Second request'
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to include('A pending revision request already exists for this task')
    end

    it 'allows a new request once the previous request is no longer pending' do
      described_class.create!(
        participant: participant,
        team: team,
        assignment: assignment,
        comments: 'First request',
        status: described_class::DECLINED
      )

      next_request = described_class.new(
        participant: participant,
        team: team,
        assignment: assignment,
        comments: 'Second request'
      )

      expect(next_request).to be_valid
    end
  end
end
