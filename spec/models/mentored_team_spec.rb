require 'rails_helper'

RSpec.describe MentoredTeam, type: :model do
  let(:role) { Role.find_or_create_by!(name: 'Student') }
  let(:instructor) do
    User.create!(
      name: 'Instructor',
      full_name: 'Instructor Name',
      email: 'instructor@example.com',
      password: 'password',
      role: Role.find_or_create_by!(name: 'Instructor')
    )
  end
  let(:course) { Course.create!(name: 'CSC 517', directory_path: 'csc517', instructor: instructor, institution: Institution.create!(name: 'NCSU')) }
  let(:assignment) { Assignment.create!(title: 'Mentored Assignment', instructor: instructor, directory_path: 'path/to/assignment', max_team_size: 2, auto_assign_mentor: false) }
  let(:student_user) { User.create!(name: 'Student', full_name: 'Student One', email: 'student1@example.com', password: 'password', role: role) }
  let(:team) { MentoredTeam.create!(name: 'Team 1', parent_id: assignment.id, assignment_id: assignment.id) }

  let!(:participant) do
    AssignmentParticipant.create!(user: student_user, assignment_id: assignment.id, handle: 'student_handle')
  end

  before do
    $redis = double('Redis', get: '')
    TeamNode.create!(node_object_id: team.id, parent_id: assignment.id)
  end

  def participant_for(user)
    AssignmentParticipant.find_by(user_id: user.id, assignment_id: assignment.id)
  end

  describe '#add_member' do
    it 'adds a participant to the team' do
      expect {
        team.add_member(participant)
      }.to change { TeamsParticipant.count }.by(1)
    end
  end

  describe '#import_team_members' do
    let!(:teammate) do
      User.create!(name: 'Teammate', full_name: 'Teammate One', email: 'teammate@example.com', password: 'password', role: role)
    end

    let!(:teammate_participant) do
      AssignmentParticipant.create!(user: teammate, assignment_id: assignment.id, handle: 'teammate_handle')
    end

    it 'adds valid users to the team' do
      expect {
        team.import_team_members(teammembers: ['Teammate'])
      }.to change { TeamsParticipant.count }.by(1)
    end

    it 'skips empty strings' do
      expect {
        team.import_team_members(teammembers: [''])
      }.not_to change { TeamsParticipant.count }
    end

    it 'raises ImportError for non-existent users' do
      expect {
        team.import_team_members(teammembers: ['GhostUser'])
      }.to raise_error(ImportError, /The user 'GhostUser' was not found/)
    end
  end

  describe '#size' do
    it 'returns 0 if only a mentor is present' do
      mentor_user = User.create!(name: 'Mentor', full_name: 'Mentor One', email: 'mentor@example.com', password: 'password', role: role)
      mentor_participant = AssignmentParticipant.create!(user: mentor_user, assignment_id: assignment.id, handle: 'mentor_handle', can_mentor: true)
      TeamsParticipant.create!(participant: mentor_participant, team: team)
      expect(team.size).to eq(0)
    end

    it 'returns correct size excluding mentor' do
      TeamsParticipant.create!(participant: participant, team: team)

      mentor_user = User.create!(name: 'Mentor2', full_name: 'Mentor Two', email: 'mentor2@example.com', password: 'password', role: role)
      mentor_participant = AssignmentParticipant.create!(user: mentor_user, assignment_id: assignment.id, handle: 'mentor_handle', can_mentor: true)
      TeamsParticipant.create!(participant: mentor_participant, team: team)

      expect(team.size).to eq(1)
    end
  end
end