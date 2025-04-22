require 'rails_helper'

RSpec.describe CourseTeam, type: :model do
  before { $redis = double('Redis', get: '') }

  let(:role) { Role.create!(name: 'Instructor') }
  let(:institution) { Institution.create!(name: 'NC State') }
  let(:instructor) do
    User.create!(
      name: 'course_instructor',
      full_name: 'Course Instructor',
      email: 'courseinstructor@example.com',
      password: 'password',
      role: role
    )
  end
  let(:course) do
    Course.create!(
      name: 'CSC101',
      instructor: instructor,
      institution: institution,
      directory_path: 'csc101_path'
    )
  end

  describe '#assignment_id' do
    it 'returns nil' do
      team = CourseTeam.new
      expect(team.assignment_id).to be_nil
    end
  end

  describe '#copy_members' do
    it 'copies team members and creates TeamUserNode for each' do
      old_team = CourseTeam.create!(name: 'Old Team', parent_id: course.id)
      new_team = CourseTeam.create!(name: 'New Team', parent_id: course.id)
      user = User.create!(
        name: 'member_user',
        full_name: 'Member',
        email: 'member@example.com',
        password: 'password',
        role: role
      )
      participant = CourseParticipant.create!(user: user, course: course, handle: 'member')
      TeamsParticipant.create!(participant: participant, team: old_team)

      expect {
        old_team.copy_members(new_team)
      }.to change { TeamsParticipant.count }.by(1)
                                            .and change { TeamUserNode.count }.by(1)

      expect(new_team.participants.map(&:user_id)).to include(user.id)
    end
  end

  describe '#copy_to_assignment' do
    it 'creates an AssignmentTeam and copies members' do
      old_team = CourseTeam.create!(name: 'Course Team', parent_id: course.id)
      user = User.create!(
        name: 'member_user2',
        full_name: 'Member 2',
        email: 'member2@example.com',
        password: 'password',
        role: role
      )
      participant = CourseParticipant.create!(user: user, course: course, handle: 'member2')
      TeamsParticipant.create!(team: old_team, participant: participant)

      assignment = Assignment.create!(
        title: 'Assignment 1',
        instructor: instructor,
        course_id: course.id,
        auto_assign_mentor: false
      )

      expect {
        old_team.copy_to_assignment(assignment.id)
      }.to change { AssignmentTeam.count }.by(1)
    end
  end

  describe '#participant_class' do
    it 'returns CourseParticipant class' do
      expect(CourseTeam.new.participant_class).to eq(CourseParticipant)
    end
  end

  describe '#import' do
    it 'delegates to Team.import' do
      row = { teamname: 'Course Team', teammembers: ['testuser'] }
      options = { has_teamname: 'true_first', handle_dups: 'insert' }

      allow(Team).to receive(:import)
      CourseTeam.import(row, course.id, options)
      expect(Team).to have_received(:import).with(row, course.id, options, CourseTeam)
    end
  end

  describe '#export' do
    it 'delegates to Team.export' do
      csv = []
      options = { team_name: 'false' }

      allow(Team).to receive(:export)
      CourseTeam.export(csv, course.id, options)
      expect(Team).to have_received(:export).with(csv, course.id, options, CourseTeam)
    end
  end

  describe '#export_fields' do
    it 'returns correct fields based on options' do
      expect(CourseTeam.export_fields(team_name: 'true')).to eq(['Team Name', 'Course Name'])
      expect(CourseTeam.export_fields(team_name: 'false')).to eq(['Team Name', 'Team members', 'Course Name'])
    end
  end
end
