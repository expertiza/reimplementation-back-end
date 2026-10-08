# frozen_string_literal: true

require 'rails_helper'
require 'net/http'

RSpec.describe AssignmentTeam, type: :model do
  
  include RolesHelper
  # --------------------------------------------------------------------------
  # Global Setup
  # --------------------------------------------------------------------------
  # Create the roles hierarchy within each example's database isolation.
  before(:each) do
    @roles = create_roles_hierarchy
  end

  # ------------------------------------------------------------------------
  # Helper: DRY-up creation of student users with a predictable pattern.
  # ------------------------------------------------------------------------
  def create_student(suffix)
    User.create!(
      name:            suffix,
      email:           "#{suffix}@example.com",
      full_name:       suffix.split('_').map(&:capitalize).join(' '),
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  def register_participant(suffix, parent = assignment, user = create_student(suffix))
    AssignmentParticipant.create!(assignment: parent, user: user, handle: user.name)
  end

  def link_participant(team, participant)
    TeamsParticipant.create!(team: team, participant: participant, user: participant.user)
  end

  # ------------------------------------------------------------------------
  # Shared Data Setup: Build core domain objects used across tests.
  # ------------------------------------------------------------------------
  let(:institution) do
    # All users belong to the same institution to satisfy foreign key constraints.
    Institution.create!(name: "NC State")
  end

  let(:instructor) do
    # The instructor will own assignments and courses in subsequent tests.
    User.create!(
      name:            "instructor",
      full_name:       "Instructor User",
      email:           "instructor@example.com",
      password_digest: "password",
      role_id:          @roles[:instructor].id,
      institution_id:  institution.id
    )
  end

  let(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  let(:other_assignment) { Assignment.create!(name: 'Assignment 2', instructor: instructor, max_team_size: 3) }

  let(:assignment_team) do
    AssignmentTeam.create!(
      parent_id:      assignment.id,
      name:           'team 1',
    )
  end


  describe 'validations' do
    it 'is valid with valid attributes' do
      # Checks validation on an unsaved team without relying on successful creation first.
      expect(AssignmentTeam.new(assignment: assignment, name: 'Valid team')).to be_valid
    end

    it 'is not valid without an assignment' do
      # Verifies the assignment-specific error without factory callbacks altering parent_id.
      team = AssignmentTeam.new(name: 'Missing assignment', assignment: nil)
      expect(team).not_to be_valid
      expect(team.errors[:assignment]).to include("must exist")
    end

    it 'rejects an unsupported STI type' do
      # Checks the inherited type inclusion validation while keeping other attributes valid.
      team = AssignmentTeam.new(assignment: assignment, name: 'Invalid type')
      team.type = 'WrongType'
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("must be 'Assignment' or 'Course' or 'Mentor'")
    end
  end

  describe '#add_member' do
    context 'when user is not enrolled in the assignment' do
      it 'returns an enrollment error without adding a membership' do
        # Verifies both the failure result and unchanged membership state for an unenrolled user.
        unenrolled_user = create_student("add_user")
        assignment_team
        result = nil
        expect {
          result = assignment_team.add_member(unenrolled_user)
        }.not_to change(TeamsParticipant, :count)
        expect(result[:success]).to be false
        expect(result[:error]).to eq("#{unenrolled_user.name} is not a participant in this assignment")
      end
    end
  end

  describe 'associations' do
    # Checks that assignment ownership is declared on the model.
    it { should belong_to(:assignment) }
    # Checks that team destruction is configured to destroy membership joins.
    it { should have_many(:teams_participants).dependent(:destroy) }
    # Checks that users are associated through participant memberships.
    it { should have_many(:users).through(:teams_participants) }
  end

  describe '#add_participant' do
    it 'creates and returns the membership for the supplied participant' do
      # Verifies the persisted join identity and record return contract of add_participant.
      participant = register_participant('new_member')
      assignment_team
      membership = nil

      expect {
        membership = assignment_team.add_participant(participant)
      }.to change(TeamsParticipant, :count).by(1)

      expect(membership).to be_persisted
      expect(membership.reload).to have_attributes(
        team_id: assignment_team.id, participant_id: participant.id, user_id: participant.user_id
      )
      expect(assignment_team.participants.reload).to contain_exactly(participant)
    end

    it 'returns the existing membership when below capacity' do
      # Ensures repeated addition reuses the original join instead of creating or replacing it.
      participant = register_participant('existing_member')
      original = link_participant(assignment_team, participant)
      result = nil

      expect {
        result = assignment_team.add_participant(participant)
      }.not_to change { TeamsParticipant.order(:id).pluck(:id) }
      expect(result.id).to eq(original.id)
    end

    it 'raises without changing memberships when the team is at capacity' do
      # Exercises the real capacity guard and the exception contract unique to add_participant.
      3.times { |index| link_participant(assignment_team, register_participant("member_#{index}")) }
      extra = register_participant('extra_member')
      original_ids = TeamsParticipant.order(:id).pluck(:id)

      expect {
        assignment_team.add_participant(extra)
      }.to raise_error(TeamFullError, 'Team is full.')
      expect(TeamsParticipant.order(:id).pluck(:id)).to eq(original_ids)
    end
  end

  describe '#remove_participant' do
    it 'removes only the targeted membership and retracts a sent invitation' do
      # Verifies scoped removal and persisted invitation retraction through remove_participant.
      participant = register_participant('departing')
      remaining = register_participant('remaining')
      invitee = register_participant('invitee')
      target = link_participant(assignment_team, participant)
      retained = link_participant(assignment_team, remaining)
      other_team = AssignmentTeam.create!(assignment: assignment, name: 'Other team')
      other_membership = link_participant(other_team, participant)
      invitation = Invitation.create!(assignment: assignment, from_id: participant.id,
                                      to_id: invitee.id, reply_status: InvitationValidator::WAITING_STATUS)

      assignment_team.remove_participant(participant)

      expect(TeamsParticipant.exists?(target.id)).to be false
      expect(TeamsParticipant.order(:id).pluck(:id)).to match_array([retained.id, other_membership.id])
      expect(assignment_team.participants.reload).to contain_exactly(remaining)
      expect(invitation.reload.reply_status).to eq(InvitationValidator::RETRACT_STATUS)
      expect(AssignmentParticipant.exists?(participant.id)).to be true
    end

    it 'leaves memberships unchanged when the participant is not on this team' do
      # Checks the missing-join branch without deleting the participant's membership elsewhere.
      participant = register_participant('elsewhere')
      link_participant(assignment_team, register_participant('staying'))
      other_team = AssignmentTeam.create!(assignment: assignment, name: 'Other team')
      link_participant(other_team, participant)

      expect {
        assignment_team.remove_participant(participant)
      }.not_to change { TeamsParticipant.order(:id).pluck(:id) }
    end
  end

  describe '#submit_hyperlink' do
    let(:original_link) { 'https://example.org/original' }

    before do
      assignment_team.update!(submitted_hyperlinks: YAML.dump([original_link]))
    end

    it 'normalizes an unprefixed URL and persists it alongside existing links' do
      # Verifies whitespace removal, HTTPS defaulting, persistence, and preservation of prior links.
      normalized = 'https://example.org/new'
      expect(Net::HTTP).to receive(:get_response).with(URI(normalized))
        .and_return(Net::HTTPOK.new('1.1', '200', 'OK'))

      result = assignment_team.submit_hyperlink(String.new('  example.org/new  '))

      expect(result).to be true
      expect(assignment_team.reload.hyperlinks).to eq([original_link, normalized])
    end

    %w[http https].each do |scheme|
      it "preserves an existing #{scheme} scheme" do
        # Checks that an explicitly supplied supported scheme is neither replaced nor prefixed again.
        link = "#{scheme}://example.org/new"
        expect(Net::HTTP).to receive(:get_response).with(URI(link))
          .and_return(Net::HTTPOK.new('1.1', '200', 'OK'))

        expect(assignment_team.submit_hyperlink(link)).to be true
        expect(assignment_team.reload.hyperlinks).to eq([original_link, link])
      end
    end

    it 'rejects whitespace-only input before networking or changing stored links' do
      # Checks the explicit empty-input error and ensures rejection has no submission side effect.
      original_storage = assignment_team.submitted_hyperlinks
      expect(Net::HTTP).not_to receive(:get_response)

      expect {
        assignment_team.submit_hyperlink(String.new('   '))
      }.to raise_error(RuntimeError, 'The hyperlink cannot be empty!')
      expect(assignment_team.submitted_hyperlinks).to eq(original_storage)
      expect(assignment_team.reload.submitted_hyperlinks).to eq(original_storage)
    end

    [Net::HTTPNotFound.new('1.1', '404', 'Not Found'),
     Net::HTTPInternalServerError.new('1.1', '500', 'Internal Server Error')].each do |http_response|
      it "rejects HTTP #{http_response.code} without changing stored links" do
        # Verifies that an HTTP error prevents both in-memory submission changes and persistence.
        original_storage = assignment_team.submitted_hyperlinks
        link = String.new('https://example.org/rejected')
        expect(Net::HTTP).to receive(:get_response).with(URI(link)).and_return(http_response)

        expect {
          assignment_team.submit_hyperlink(link)
        }.to raise_error(RuntimeError, /HTTP status code:/)
        expect(assignment_team.submitted_hyperlinks).to eq(original_storage)
        expect(assignment_team.reload.submitted_hyperlinks).to eq(original_storage)
      end
    end
  end

  describe '#remove_hyperlink' do
    it 'persists removal of the requested value while preserving other links' do
      # Checks value-based removal and its save result using reloaded submission data.
      removed = 'https://example.org/removed'
      retained = 'https://example.org/retained'
      assignment_team.update!(submitted_hyperlinks: YAML.dump([removed, retained]))

      expect(assignment_team.remove_hyperlink(removed)).to be true
      expect(assignment_team.reload.hyperlinks).to eq([retained])
    end
  end

  describe '.team' do
    it 'returns the team belonging to each participant assignment for the same user' do
      # Checks both lookups so returning the user's first membership cannot satisfy the example.
      participant = register_participant('shared_user')
      other_participant = register_participant('unused', other_assignment, participant.user)
      other_team = AssignmentTeam.create!(assignment: other_assignment, name: 'Other assignment team')
      link_participant(assignment_team, participant)
      link_participant(other_team, other_participant)

      expect(described_class.team(participant)).to eq(assignment_team)
      expect(described_class.team(other_participant)).to eq(other_team)
    end

    it 'returns nil when the user has a team only in another assignment' do
      # Ensures an unrelated assignment membership is not returned as the participant's team.
      participant = register_participant('unmatched')
      other_participant = register_participant('unused', other_assignment, participant.user)
      other_team = AssignmentTeam.create!(assignment: other_assignment, name: 'Other assignment team')
      link_participant(other_team, other_participant)

      expect(described_class.team(participant)).to be_nil
    end

    it 'returns nil for a nil participant' do
      # Checks the public nil-input guard without requiring any membership records.
      expect(described_class.team(nil)).to be_nil
    end
  end

  describe '#aggregate_reviewer_score' do
    it 'passes only this team and assignment mappings to the calculator and returns its result' do
      # Exercises real association filtering while leaving score arithmetic to ResponseMap's specs.
      reviewer = register_participant('reviewer')
      matching = ReviewResponseMap.create!(assignment: assignment, reviewee: assignment_team, reviewer: reviewer)
      other_team = AssignmentTeam.create!(assignment: assignment, name: 'Other reviewed team')
      ReviewResponseMap.create!(assignment: assignment, reviewee: other_team, reviewer: reviewer)
      ReviewResponseMap.create!(assignment: other_assignment, reviewee: assignment_team, reviewer: reviewer)
      calculator_result = 73.25
      expect(ResponseMap).to receive(:compute_average_reviewer_score) do |maps|
        expect(maps.to_a).to contain_exactly(matching)
        calculator_result
      end

      expect(assignment_team.aggregate_reviewer_score).to eq(calculator_result)
    end
  end
end 
