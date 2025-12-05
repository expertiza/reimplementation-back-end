require 'rails_helper'

RSpec.describe JoinTeamRequest, type: :model do
  include ActiveJob::TestHelper

  let(:role) { Role.create(name: 'Instructor', parent_id: nil, id: 3, default_page_id: nil) }
  let(:student_role) { Role.create(name: 'Student', parent_id: nil, id: 5, default_page_id: nil) }
  let(:instructor) { Instructor.create(name: 'testinstructor', email: 'instructor@test.com', full_name: 'Test Instructor', password: '123456', role: role) }
  let(:requester) { create :user, name: 'requester_user', role: student_role, email: 'requester@test.com' }
  let(:team_member) { create :user, name: 'team_member_user', role: student_role, email: 'team_member@test.com' }
  let(:another_user) { create :user, name: 'another_user', role: student_role, email: 'another@test.com' }
  let(:assignment) { create(:assignment, instructor: instructor, max_team_size: 3) }
  let(:team) { AssignmentTeam.create(name: 'Test Team', parent_id: assignment.id, type: 'AssignmentTeam') }
  let(:another_team) { AssignmentTeam.create(name: 'Another Team', parent_id: assignment.id, type: 'AssignmentTeam') }
  let(:requester_participant) { AssignmentParticipant.create(user_id: requester.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'requester_handle') }
  let(:team_member_participant) { AssignmentParticipant.create(user_id: team_member.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'team_member_handle') }
  let(:another_participant) { AssignmentParticipant.create(user_id: another_user.id, parent_id: assignment.id, type: 'AssignmentParticipant', handle: 'another_handle') }

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
    TeamsParticipant.create(team_id: team.id, participant_id: team_member_participant.id, user_id: team_member.id)
  end

  after(:each) do
    clear_enqueued_jobs
  end

  # --------------------------------------------------------------------------
  # Association Tests
  # --------------------------------------------------------------------------
  describe 'associations' do
    it 'belongs to participant' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, team_id: team.id)
      expect(join_request).to belong_to(:participant)
    end

    it 'belongs to team' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, team_id: team.id)
      expect(join_request).to belong_to(:team)
    end

    it 'can access participant user through association' do
      join_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      expect(join_request.participant.user).to eq(requester)
    end

    it 'can access team assignment through association' do
      join_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      expect(join_request.team.assignment).to eq(assignment)
    end
  end

  # --------------------------------------------------------------------------
  # Validation Tests
  # --------------------------------------------------------------------------
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
      join_request = JoinTeamRequest.new(team_id: team.id, comments: 'Join please', reply_status: 'PENDING')
      expect(join_request).not_to be_valid
      expect(join_request.errors[:participant]).to include("must exist")
    end

    it 'requires team_id' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, comments: 'Join please', reply_status: 'PENDING')
      expect(join_request).not_to be_valid
      expect(join_request.errors[:team]).to include("must exist")
    end

    it 'validates reply_status inclusion' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'INVALID_STATUS'
      )
      expect(join_request).not_to be_valid
      expect(join_request.errors[:reply_status]).to include("is not included in the list")
    end

    it 'accepts PENDING as valid reply_status' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      expect(join_request).to be_valid
    end

    it 'accepts ACCEPTED as valid reply_status' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'ACCEPTED'
      )
      expect(join_request).to be_valid
    end

    it 'accepts DECLINED as valid reply_status' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'DECLINED'
      )
      expect(join_request).to be_valid
    end
  end

  # --------------------------------------------------------------------------
  # Creation and Attributes Tests
  # --------------------------------------------------------------------------
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

    it 'allows creating without explicit reply_status' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect(join_request).to be_persisted
      expect(join_request.reply_status).to eq('PENDING')
    end

    it 'allows empty comments' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      expect(join_request).to be_valid
      expect(join_request.comments).to be_nil
    end

    it 'allows updating comments' do
      join_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        comments: 'Original comment',
        reply_status: 'PENDING'
      )

      join_request.update!(comments: 'Updated comment')
      expect(join_request.reload.comments).to eq('Updated comment')
    end
  end

  # --------------------------------------------------------------------------
  # Relationship Tests
  # --------------------------------------------------------------------------
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

    it 'is destroyed when the team is destroyed' do
      join_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect { team.destroy }.to change(JoinTeamRequest, :count).by(-1)
    end
  end

  # --------------------------------------------------------------------------
  # Status Transition Tests
  # --------------------------------------------------------------------------
  describe 'status transitions' do
    let(:join_request) do
      JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
    end

    it 'can transition from PENDING to ACCEPTED' do
      join_request.update!(reply_status: 'ACCEPTED')
      expect(join_request.reload.reply_status).to eq('ACCEPTED')
    end

    it 'can transition from PENDING to DECLINED' do
      join_request.update!(reply_status: 'DECLINED')
      expect(join_request.reload.reply_status).to eq('DECLINED')
    end

    it 'persists status changes' do
      join_request.update!(reply_status: 'ACCEPTED')
      reloaded = JoinTeamRequest.find(join_request.id)
      expect(reloaded.reply_status).to eq('ACCEPTED')
    end
  end

  # --------------------------------------------------------------------------
  # Query Tests
  # --------------------------------------------------------------------------
  describe 'queries' do
    before do
      @pending_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      @accepted_request = JoinTeamRequest.create!(
        participant_id: another_participant.id,
        team_id: team.id,
        reply_status: 'ACCEPTED'
      )
    end

    it 'can filter by PENDING status' do
      pending_requests = JoinTeamRequest.where(reply_status: 'PENDING')
      expect(pending_requests).to include(@pending_request)
      expect(pending_requests).not_to include(@accepted_request)
    end

    it 'can filter by ACCEPTED status' do
      accepted_requests = JoinTeamRequest.where(reply_status: 'ACCEPTED')
      expect(accepted_requests).to include(@accepted_request)
      expect(accepted_requests).not_to include(@pending_request)
    end

    it 'can find requests by team_id' do
      team_requests = JoinTeamRequest.where(team_id: team.id)
      expect(team_requests.count).to eq(2)
    end

    it 'can find requests by participant_id' do
      participant_requests = JoinTeamRequest.where(participant_id: requester_participant.id)
      expect(participant_requests).to include(@pending_request)
      expect(participant_requests.count).to eq(1)
    end

    it 'can check for existing pending request' do
      existing = JoinTeamRequest.find_by(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      expect(existing).to eq(@pending_request)
    end
  end

  # --------------------------------------------------------------------------
  # Multiple Requests Tests
  # --------------------------------------------------------------------------
  describe 'multiple requests' do
    it 'allows same participant to request different teams' do
      request1 = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      request2 = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: another_team.id,
        reply_status: 'PENDING'
      )

      expect(request1).to be_persisted
      expect(request2).to be_persisted
    end

    it 'allows different participants to request same team' do
      request1 = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      request2 = JoinTeamRequest.create!(
        participant_id: another_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect(request1).to be_persisted
      expect(request2).to be_persisted
      expect(team.join_team_requests.count).to eq(2)
    end

    it 'retrieves all requests for a team through association' do
      JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      JoinTeamRequest.create!(
        participant_id: another_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect(team.join_team_requests.count).to eq(2)
    end
  end

  # --------------------------------------------------------------------------
  # Edge Cases Tests
  # --------------------------------------------------------------------------
  describe 'edge cases' do
    it 'handles long comments' do
      long_comment = 'A' * 1000
      join_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        comments: long_comment,
        reply_status: 'PENDING'
      )
      expect(join_request.comments).to eq(long_comment)
    end

    it 'handles special characters in comments' do
      special_comment = "Hello! I'd like to join. <script>alert('test')</script>"
      join_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        comments: special_comment,
        reply_status: 'PENDING'
      )
      expect(join_request.comments).to eq(special_comment)
    end

    it 'handles unicode in comments' do
      unicode_comment = "I'd like to join! 🚀 こんにちは"
      join_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        comments: unicode_comment,
        reply_status: 'PENDING'
      )
      expect(join_request.comments).to eq(unicode_comment)
    end
  end
end
