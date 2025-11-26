require 'rails_helper'

RSpec.describe JoinTeamRequest, type: :model do
  include ActiveJob::TestHelper

  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 3, default_page_id: nil) }
  let(:student_role) { Role.create(name: 'Student', parent_id: nil, id: 5, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'instructor@test.com', full_name: 'Test Instructor', password: '123456', role: role) }
  let(:requester) { create :user, name: 'requester_user', role: student_role, email: 'requester@test.com' }
  let(:team_member) { create :user, name: 'team_member_user', role: student_role, email: 'team_member@test.com' }
  let(:assignment) { create(:assignment, instructor: instructor, max_team_size: 3) }
  let(:team) { AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam') }
  let(:requester_participant) { AssignmentParticipant.create(user_id: requester.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'requester_handle') }
  let(:team_member_participant) { AssignmentParticipant.create(user_id: team_member.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'team_member_handle') }

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    TeamsParticipant.create(team_id: team.id, participant_id: team_member_participant.id, user_id: team_member.id)
  end

  after(:each) do
    clear_enqueued_jobs
  end

  describe 'associations' do
    it 'belongs to participant' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, team_id: team.id)
      expect(join_request).to belong_to(:participant)
    end

    it 'belongs to team' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, team_id: team.id)
      expect(join_request).to belong_to(:team)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        comments: 'Please let me join',
        reply_status: 'PENDING'
      )
      expect(join_request).to be_valid
    end

    it 'requires participant_id' do
      join_request = JoinTeamRequest.new(team_id: team.id, comments: 'Join please')
      expect(join_request).not_to be_valid
    end

    it 'requires team_id' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, comments: 'Join please')
      expect(join_request).not_to be_valid
    end
  end

  describe 'creation and attributes' do
    it 'creates a join request with correct attributes' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id,
        comments: 'I want to join your team',
        reply_status: 'PENDING'
      )

      expect(join_request.participant_id).to eq(requester_participant.id)
      expect(join_request.team_id).to eq(team.id)
      expect(join_request.comments).to eq('I want to join your team')
      expect(join_request.reply_status).to eq('PENDING')
    end

    it 'sets reply_status to PENDING by default' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id
      )

      expect(join_request.reply_status).to eq('PENDING')
    end
  end

  describe 'relationships' do
    it 'returns correct participant' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id
      )

      expect(join_request.participant).to eq(requester_participant)
    end

    it 'returns correct team' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id
      )

      expect(join_request.team).to eq(team)
    end
  end
end
