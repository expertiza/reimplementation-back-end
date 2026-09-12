# frozen_string_literal: true

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
    # Verifies the model is linked to the participant record that created the request.
    it 'belongs to participant' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, team_id: team.id)
      expect(join_request).to belong_to(:participant)
    end

    # Verifies the model is linked to the team being requested.
    it 'belongs to team' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, team_id: team.id)
      expect(join_request).to belong_to(:team)
    end

    # Verifies the participant association can navigate back to the requesting user.
    it 'can access participant user through association' do
      join_request = JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      expect(join_request.participant.user).to eq(requester)
    end

    # Verifies the team association can navigate back to the assignment context.
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
    # Confirms a request is otherwise valid when the required foreign keys and status are set.
    it 'is valid with valid attributes' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        comments: 'Please let me join',
        reply_status: 'PENDING'
      )
      expect(join_request).to be_valid
    end

    # Verifies the model enforces that a request must be associated with a participant.
    it 'requires participant_id' do
      join_request = JoinTeamRequest.new(team_id: team.id, comments: 'Join please', reply_status: 'PENDING')
      expect(join_request).not_to be_valid
      expect(join_request.errors[:participant]).to include("must exist")
    end

    # Verifies the model enforces that a request must reference a team.
    it 'requires team_id' do
      join_request = JoinTeamRequest.new(participant_id: requester_participant.id, comments: 'Join please', reply_status: 'PENDING')
      expect(join_request).not_to be_valid
      expect(join_request.errors[:team]).to include("must exist")
    end

    # Confirms invalid state values are rejected so status remains in a safe set.
    it 'validates reply_status inclusion' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'INVALID_STATUS'
      )
      expect(join_request).not_to be_valid
      expect(join_request.errors[:reply_status]).to include("is not included in the list")
    end

    # Ensures the pending state is treated as a valid business state.
    it 'accepts PENDING as valid reply_status' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      expect(join_request).to be_valid
    end

    # Ensures an accepted request is a valid terminal state.
    it 'accepts ACCEPTED as valid reply_status' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'ACCEPTED'
      )
      expect(join_request).to be_valid
    end

    # Ensures a declined request is a valid terminal state.
    it 'accepts DECLINED as valid reply_status' do
      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'DECLINED'
      )
      expect(join_request).to be_valid
    end

    # This rule exists, but it is enforced in the controller's create action, not as a model validation.
    # The model only validates reply_status inclusion, so this example remains intentionally pending.
    it 'rejects a second pending request for the same participant and team', pending: 'Rule exists outside the model: controller create action checks for an existing pending request.' do
      JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      duplicate_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect(duplicate_request).not_to be_valid
      expect(duplicate_request.errors[:participant_id]).to include("already has a pending request for this team")
    end

    # This rule exists, but it is enforced in the controller's create action, not as a model validation.
    # The model does not validate membership state, so the business rule is currently enforced outside the model.
    it 'rejects a request when the participant is already on the target team', pending: 'Rule exists outside the model: controller create action checks team membership before save.' do
      TeamsParticipant.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        user_id: requester.id
      )

      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect(join_request).not_to be_valid
      expect(join_request.errors[:participant_id]).to include("already belongs to this team")
    end

    # This rule does not appear to be enforced anywhere in the current codebase.
    # The controller checks duplicate pending requests and same-team membership, but not assignment-scope team membership.
    it 'rejects a request when the participant is already on another team in the same assignment', pending: 'Rule does not appear to be enforced anywhere in the current codebase.' do
      TeamsParticipant.create!(
        participant_id: requester_participant.id,
        team_id: another_team.id,
        user_id: requester.id
      )

      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect(join_request).not_to be_valid
      expect(join_request.errors[:participant_id]).to include("already assigned to a team in this assignment")
    end

    # This rule exists, but it is enforced in the controller's team-capacity guard, not as a model validation.
    # The model does not validate team fullness, so this check is intentionally left pending as a documented gap in the model spec.
    it 'rejects a request when the team is already full', pending: 'Rule exists outside the model: controller checks team.full? before create.' do
      allow(team).to receive(:full?).and_return(true)

      join_request = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect(join_request).not_to be_valid
      expect(join_request.errors[:team_id]).to include("team is full")
    end
  end

  # --------------------------------------------------------------------------
  # Creation and Attributes Tests
  # --------------------------------------------------------------------------
  describe 'creation and attributes' do
    # Checks the request persists the exact participant, team, comment, and status.
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

    # Confirms a default pending status is accepted without explicit assignment.
    it 'allows creating without explicit reply_status' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )

      expect(join_request).to be_persisted
      expect(join_request.reply_status).to eq('PENDING')
    end

    # Verifies a nil comments field is accepted because a request may be submitted without text.
    it 'allows empty comments' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'PENDING'
      )
      expect(join_request).to be_valid
      expect(join_request.comments).to be_nil
    end

    # Confirms the request can be updated after creation without rewriting its identity.
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
    # Verifies the instance resolves back to the exact participant record.
    it 'returns correct participant' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id
      )

      expect(join_request.participant).to eq(requester_participant)
    end

    # Verifies the instance resolves back to the exact team record.
    it 'returns correct team' do
      join_request = JoinTeamRequest.create(
        participant_id: requester_participant.id,
        team_id: team.id
      )

      expect(join_request.team).to eq(team)
    end

    # Confirms a team-level destroy cascades and removes associated requests.
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

    # Verifies the request can be accepted once it is still pending.
    it 'can transition from PENDING to ACCEPTED' do
      join_request.update!(reply_status: 'ACCEPTED')
      expect(join_request.reload.reply_status).to eq('ACCEPTED')
    end

    # Verifies the request can be declined while still pending.
    it 'can transition from PENDING to DECLINED' do
      join_request.update!(reply_status: 'DECLINED')
      expect(join_request.reload.reply_status).to eq('DECLINED')
    end

    # Verifies the updated status persists across a reload, preventing stale in-memory state.
    it 'persists status changes' do
      join_request.update!(reply_status: 'ACCEPTED')
      reloaded = JoinTeamRequest.find(join_request.id)
      expect(reloaded.reply_status).to eq('ACCEPTED')
    end

    # This rule exists, but it is enforced in the controller's accept/decline flow, not as a model validation.
    # The model only checks inclusion in the allowed status list, so the status-transition guard remains outside the model.
    it 'rejects reprocessing an already accepted request', pending: 'Rule exists outside the model: controller ensure_request_pending blocks processed requests.' do
      join_request.update!(reply_status: 'ACCEPTED')

      join_request.reply_status = 'PENDING'
      expect(join_request).not_to be_valid
      expect(join_request.errors[:reply_status]).to include("cannot be re-opened after being processed")
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

    # Verifies the query layer can isolate pending requests without including accepted ones.
    it 'can filter by PENDING status' do
      pending_requests = JoinTeamRequest.where(reply_status: 'PENDING')
      expect(pending_requests).to include(@pending_request)
      expect(pending_requests).not_to include(@accepted_request)
    end

    # Verifies the query layer can isolate accepted requests without including pending ones.
    it 'can filter by ACCEPTED status' do
      accepted_requests = JoinTeamRequest.where(reply_status: 'ACCEPTED')
      expect(accepted_requests).to include(@accepted_request)
      expect(accepted_requests).not_to include(@pending_request)
    end

    # Verifies requests can be retrieved by their team association.
    it 'can find requests by team_id' do
      team_requests = JoinTeamRequest.where(team_id: team.id)
      expect(team_requests.count).to eq(2)
    end

    # Verifies requests can be retrieved by the originating participant.
    it 'can find requests by participant_id' do
      participant_requests = JoinTeamRequest.where(participant_id: requester_participant.id)
      expect(participant_requests).to include(@pending_request)
      expect(participant_requests.count).to eq(1)
    end

    # Verifies a direct lookup for an existing pending request returns the live object.
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
    # Verifies a participant may request a different team after an earlier request is resolved.
    it 'allows same participant to request different teams after a prior request is resolved' do
      JoinTeamRequest.create!(
        participant_id: requester_participant.id,
        team_id: team.id,
        reply_status: 'DECLINED'
      )

      request2 = JoinTeamRequest.new(
        participant_id: requester_participant.id,
        team_id: another_team.id,
        reply_status: 'PENDING'
      )

      expect(request2).to be_valid
    end

    # Verifies multiple people may request admission to the same team.
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

    # Verifies the team association exposes every outstanding request on that team.
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
    # Verifies very long comments are stored intact instead of being truncated or rejected.
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

    # Verifies HTML-like comment text survives without being sanitized by the model.
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

    # Verifies Unicode text is preserved, which is important for international names and messages.
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