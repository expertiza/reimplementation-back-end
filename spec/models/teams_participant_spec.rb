require 'rails_helper'

describe TeamsParticipant, type: :model do
  let(:institution) { Institution.create!(name: 'Test University') }
  let(:student_role) { Role.create!(name: 'Student') }
  let(:instructor_role) { Role.create!(name: 'Instructor') }

  let(:instructor) do
    User.create!(
      name: 'InstructorUser',
      email: 'instructor@example.com',
      full_name: 'Instructor Full Name',
      password_digest: 'password',
      role: instructor_role,
      institution: institution
    )
  end

  let(:assignment) do
    Assignment.create!(
      name: 'Test Assignment',
      instructor: instructor
    )
  end

  let(:participant1_user) do
    User.create!(
      name: 'User One',
      email: 'user1@example.com',
      full_name: 'User One Full Name',
      password_digest: 'password',
      role: student_role,
      institution: institution
    )
  end

  let(:participant2_user) do
    User.create!(
      name: 'User Two',
      email: 'user2@example.com',
      full_name: 'User Two Full Name',
      password_digest: 'password',
      role: student_role,
      institution: institution
    )
  end

  let(:assignment_participant1) do
    AssignmentParticipant.create!(
      user: participant1_user,
      assignment: assignment,
      handle: 'user1handle'
    )
  end

  let(:assignment_participant2) do
    AssignmentParticipant.create!(
      user: participant2_user,
      assignment: assignment,
      handle: 'user2handle'
    )
  end

  let(:team) { Team.create!(assignment: assignment) }

  let!(:team_participant) do
    TeamsParticipant.create!(
      participant: assignment_participant1,
      team: team
    )
  end

  describe '#name' do
    it 'returns the name of the associated participant user' do
      expect(team_participant.name).to eq(participant1_user.name)
    end
  end

  describe '.get_team_members' do
    before do
      TeamsParticipant.create!(participant: assignment_participant2, team: team)
    end

    it 'returns the users associated with the given team id' do
      members = TeamsParticipant.get_team_members(team.id)
      expect(members).to match_array([participant1_user, participant2_user])
    end

    it 'returns empty array if no participants exist for a team' do
      new_team = Team.create!(assignment: assignment)
      expect(TeamsParticipant.get_team_members(new_team.id)).to be_empty
    end
  end

  describe '.remove_team' do
    it 'removes the team participant for the given participant and team' do
      expect(TeamsParticipant.find_by(participant: assignment_participant1, team: team)).to be_present
      TeamsParticipant.remove_team(assignment_participant1.id, team.id)
      expect(TeamsParticipant.find_by(participant: assignment_participant1, team: team)).to be_nil
    end

    it 'returns nil when no matching team participant exists' do
      result = TeamsParticipant.remove_team(99999, team.id)
      expect(result).to be_nil
    end
  end

  describe 'associations' do
    it 'belongs to a participant' do
      expect(team_participant.participant).to eq(assignment_participant1)
    end

    it 'belongs to a team' do
      expect(team_participant.team).to eq(team)
    end
  end
end
