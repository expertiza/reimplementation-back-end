# frozen_string_literal: true

# Revised Team regression suite developed during the independent study.
# Compared with team_spec.rb using line coverage and mutation testing.
# Overlapping scenarios are retained for that comparison pending consolidation.

require 'rails_helper'
require 'securerandom'

RSpec.describe Team, type: :model do
  def unique_name(prefix)
    "#{prefix}_#{SecureRandom.hex(6)}"
  end

  def create_user(role_name: 'Student')
    role = Role.find_or_create_by!(name: role_name)
    User.create!(name: unique_name('user'), full_name: 'Team Study User',
                 email: "#{unique_name('user')}@example.org", role: role,
                 password: 'team-study-password', password_confirmation: 'team-study-password')
  end

  def create_parent(kind, **attributes)
    @team_test_instructor ||= create_user(role_name: 'Instructor')
    if kind == :course
      @team_test_institution ||= Institution.create!(name: unique_name('institution'))
      Course.create!({ name: unique_name('course'), directory_path: 'team-study',
                       instructor: @team_test_instructor, institution: @team_test_institution }.merge(attributes))
    else
      Assignment.create!({ name: unique_name('assignment'), has_teams: true,
                           instructor: @team_test_instructor, max_team_size: 3 }.merge(attributes))
    end
  end

  def create_team(parent, klass: nil)
    klass ||= parent.is_a?(Course) ? CourseTeam : AssignmentTeam
    klass.create!(name: unique_name('team'), parent_id: parent.id)
  end

  def create_participant(parent, user: create_user)
    klass = parent.is_a?(Course) ? CourseParticipant : AssignmentParticipant
    klass.create!(parent_id: parent.id, user: user, handle: unique_name('handle'))
  end

  def create_membership(team, participant)
    TeamsParticipant.create!(team: team, participant: participant, user: participant.user)
  end

  def create_topic(assignment)
    ProjectTopic.create!(assignment: assignment, topic_name: unique_name('topic'), max_choosers: 1)
  end

  shared_examples 'a supported team subtype' do
    # Verifies valid subtype persistence and parent resolution without a creator.
    it 'persists the supported subtype with its parent' do
      persisted_team = Team.find(team.id)

      expect(persisted_team.class).to eq(team_class)
      expect(persisted_team.public_send(parent_kind)).to eq(parent)
      expect(persisted_team).to be_valid
    end
  end

  shared_examples 'participant membership' do
    # Verifies membership distinguishes a linked user from an unrelated user.
    it 'recognizes a member and rejects a nonmember' do
      create_membership(team, participant)

      expect(team.has_member?(participant.user)).to be(true)
      expect(team.has_member?(create_user)).to be(false)
    end

    # Verifies the reported size follows persisted participant memberships.
    it 'counts empty and populated teams' do
      expect(team.team_size).to eq(0)

      create_membership(team, participant)
      create_membership(team, create_participant(parent))

      expect(team.team_size).to eq(2)
    end

    # Verifies a leftover legacy join does not count a departed user as a member.
    it 'ignores a legacy user join after current membership is removed' do
      legacy_join = TeamsUser.create!(team: team, user: participant.user)
      membership = create_membership(team, participant)
      membership.destroy!

      expect(TeamsUser.exists?(legacy_join.id)).to be(true)
      expect(team.has_member?(participant.user)).to be(false)
      expect(team.team_size).to eq(0)
    end
  end

  shared_examples 'parent-scoped membership' do
    it 'returns false when a saved member has invalid participant attributes' do
      member = participant
      create_membership(team, member)
      member.handle = nil

      expect(member).not_to be_valid
      expect(team.participant_on_team?(member)).to be(false)
      expect(team.teams_participants.exists?(participant_id: member.id)).to be(true)
    end

    %i[current sibling].each do |location|
      # Verifies membership detection across this parent's current and sibling teams.
      it "finds the participant on the #{location} team" do
        membership_team = location == :current ? team : create_team(parent)
        create_membership(membership_team, participant)

        expect(team.participant_on_team?(participant)).to be(true)
      end
    end

    # Verifies a participant without team membership is not reported as a team member.
    it 'returns false for an unassigned participant' do
      expect(team.participant_on_team?(participant)).to be(false)
    end

    # Verifies a legitimate membership under another parent does not enter this scope.
    it 'ignores membership under another parent' do
      other_parent = create_parent(parent_kind)
      other_participant = create_participant(other_parent)
      create_membership(create_team(other_parent), other_participant)

      expect(team.participant_on_team?(other_participant)).to be(false)
    end
  end

  shared_examples 'direct participant admission' do
    # Verifies admission persists exactly the supplied team, participant and user relationship.
    it 'adds a participant with the correct membership' do
      candidate = participant
      target = team
      existing_member = create_participant(parent)
      create_membership(target, existing_member)
      result = nil

      expect { result = target.add_member(candidate) }.to change(TeamsParticipant, :count).by(1)

      expect(result).to eq(success: true)
      expect(target.teams_participants.pluck(:participant_id, :user_id)).to match_array(
        [[existing_member.id, existing_member.user_id], [candidate.id, candidate.user_id]]
      )
      expect(target.participants).to contain_exactly(existing_member, candidate)
      expect(target.users).to contain_exactly(existing_member.user, candidate.user)
    end

    # Verifies repeated admission cannot create a second membership for the same participant.
    it 'rejects an existing member without changing the membership' do
      membership = create_membership(team, participant)
      result = nil

      expect { result = team.add_member(participant) }.not_to change(TeamsParticipant, :count)

      expect(result.fetch(:success)).to be(false)
      expect(team.teams_participants.pluck(:id)).to eq([membership.id])
    end
  end

  shared_examples 'admission input handling' do
    it 'rejects an invalid saved participant without creating membership' do
      candidate = participant
      target = team
      candidate.handle = nil
      result = nil

      expect(candidate).not_to be_valid
      expect { result = target.add_member(candidate) }.not_to change(TeamsParticipant, :count)
      expect(result).to eq(success: false, error: 'Participant is not assigned to this team')
      expect(target.can_participant_join_team?(candidate)).to eq(result)
      expect(target.participants).to be_empty
    end

    it 'rejects admission when the team has no parent' do
      target = team_class.new(name: unique_name('orphan'))
      candidate = participant
      result = nil

      expect { result = target.add_member(candidate) }.not_to change(TeamsParticipant, :count)
      expect(result).to eq(success: false, error: 'Participant is not assigned to this team')
    end

    it 'rejects a User object instead of a Participant' do
      candidate = participant
      target = team
      result = nil

      expect { result = target.add_member(candidate.user) }.not_to change(TeamsParticipant, :count)

      expect(result).to eq(success: false, error: 'Participant is not assigned to this team')
      expect(target.participants).to be_empty
    end

    it 'rejects a participant object belonging to another parent' do
      candidate = create_participant(create_parent(parent_kind))
      target = team
      result = nil

      expect { result = target.add_member(candidate) }.not_to change(TeamsParticipant, :count)

      expect(result.fetch(:success)).to be(false)
      expect(result.fetch(:error)).to eq('Participant is not assigned to this team')
      expect(target.participants).to be_empty
    end

    it 'rejects an unsaved participant without persisting it' do
      candidate = participant.dup
      target = team
      result = nil
      original_participant_count = Participant.count

      # A valid object is not necessarily saved or assigned to the destination.
      expect(candidate).to be_valid
      expect { result = target.add_member(candidate) }.not_to change(TeamsParticipant, :count)

      expect(result.fetch(:success)).to be(false)
      expect(result.fetch(:error)).to eq('Participant is not assigned to this team')
      expect(candidate).to be_new_record
      expect(Participant.count).to eq(original_participant_count)
      expect(target.participants).to be_empty
    end

    it 'rejects the wrong participant subtype' do
      other_kind = parent_kind == :assignment ? :course : :assignment
      candidate = create_participant(create_parent(other_kind))
      target = team
      result = nil

      expect { result = target.add_member(candidate) }.not_to change(TeamsParticipant, :count)

      expect(result.fetch(:success)).to be(false)
      expect(result.fetch(:error)).to eq('Participant is not assigned to this team')
      expect(target.participants).to be_empty
    end

    it 'returns an input error for nil without creating membership' do
      target = team
      result = nil

      expect { result = target.add_member(nil) }.not_to change(TeamsParticipant, :count)

      expect(result.fetch(:success)).to be(false)
      expect(result.fetch(:error)).to eq('Participant is not assigned to this team')
      expect(target.participants).to be_empty
    end
  end

  shared_examples 'destination participant lookup' do
    it 'copies the intended user using the destination participant record' do
      source_parent = create_parent(parent_kind == :assignment ? :course : :assignment)
      source_team = create_team(source_parent)
      user = create_user
      source_participant = create_participant(source_parent, user: user)
      create_membership(source_team, source_participant)
      unrelated_participant = create_participant(parent)
      destination_participant = create_participant(parent, user: user)

      TeamOperationsHelper.copy_team_members(source_team, team)

      expect(team.reload.participants).to contain_exactly(destination_participant)
      expect(team.teams_participants.pluck(:user_id)).to eq([user.id])
      expect(team.participants).not_to include(source_participant, unrelated_participant)
    end

    it 'does not copy a user without a participant record in the destination assignment or course' do
      source_parent = create_parent(parent_kind == :assignment ? :course : :assignment)
      source_team = create_team(source_parent)
      source_participant = create_participant(source_parent)
      create_membership(source_team, source_participant)
      create_participant(parent)
      target = team

      expect { TeamOperationsHelper.copy_team_members(source_team, target) }
        .not_to change(TeamsParticipant, :count)
      expect(target.participants).to be_empty
    end
  end

  shared_examples 'participant eligibility' do
    # Verifies a participant without conflicting team membership is eligible.
    it 'accepts a participant without a team' do
      expect(team.can_participant_join_team?(participant)).to eq(success: true)
    end

    # Verifies ordinary admission rejects an existing membership within the parent scope.
    it 'rejects a participant already on a sibling team' do
      sibling = create_team(parent)
      create_membership(sibling, participant)

      expect(team.can_participant_join_team?(participant).fetch(:success)).to be(false)
      expect(sibling.participants).to contain_exactly(participant)
      expect(team.participants).to be_empty
    end

    # Verifies a participant assigned elsewhere does not satisfy the target parent's enrollment rule.
    it 'rejects a participant assigned only to another assignment or course' do
      other_participant = create_participant(create_parent(parent_kind))
      create_participant(parent) # Another participant's assignment must not establish eligibility.

      expect(team.can_participant_join_team?(other_participant).fetch(:success)).to be(false)
      expect(team.participants).to be_empty
    end
  end

  shared_examples 'ordinary member removal' do
    # Verifies departure removes only the selected membership from a populated team.
    it 'preserves the team and remaining members after one member leaves' do
      departing = participant
      remaining = create_participant(parent)
      create_membership(team, remaining)
      create_membership(team, departing)

      team.remove_member(departing)

      expect(team.reload.participants).to contain_exactly(remaining)
      expect(Participant.exists?(departing.id)).to be(true)
      expect(Participant.exists?(remaining.id)).to be(true)
    end

    # Verifies final departure destroys the empty team while preserving the participant.
    it 'destroys the team when its last member leaves' do
      departing = participant
      membership = create_membership(team, departing)

      team.remove_member(departing)

      expect(Team.exists?(team.id)).to be(false)
      expect(TeamsParticipant.exists?(membership.id)).to be(false)
      expect(Participant.exists?(departing.id)).to be(true)
    end
  end

  { assignment: AssignmentTeam, course: CourseTeam }.each do |kind, klass|
    context "with a #{kind} team" do
      let(:parent_kind) { kind }
      let(:parent) { create_parent(parent_kind) }
      let(:team_class) { klass }
      let(:team) { create_team(parent, klass: team_class) }
      let(:participant) { create_participant(parent) }

      include_examples 'a supported team subtype'
      include_examples 'participant membership'
      include_examples 'parent-scoped membership'
      include_examples 'direct participant admission'
      include_examples 'admission input handling'
      include_examples 'destination participant lookup'
      include_examples 'participant eligibility'
      include_examples 'ordinary member removal'
    end
  end

  context 'with a mentored team' do
    let(:parent_kind) { :assignment }
    let(:parent) { create_parent(parent_kind) }
    let(:team_class) { MentoredTeam }
    let(:team) { create_team(parent, klass: team_class) }
    let(:participant) { create_participant(parent) }

    include_examples 'a supported team subtype'
    include_examples 'participant eligibility'
    include_examples 'direct participant admission'
  end

  describe 'owned validations' do
    # Verifies Team rejects creation without its required parent identifier.
    it 'requires a parent identifier' do
      team = AssignmentTeam.new(name: unique_name('team'))
      team.validate

      expect(team.errors.of_kind?(:parent_id, :blank)).to be(true)
    end

    { nil => :blank, 'UnsupportedTeam' => :inclusion }.each do |type_value, error_kind|
      # Verifies the explicit type validator rejects a missing or unsupported subtype.
      it "rejects type #{type_value.inspect}" do
        parent = create_parent(:assignment)
        team = AssignmentTeam.new(name: unique_name('team'), assignment: parent)
        team.type = type_value
        team.validate

        expect(team.errors.of_kind?(:type, error_kind)).to be(true)
      end
    end
  end

  describe 'parent scope identity' do
    # Verifies overlapping assignment and course IDs do not mix their team collections.
    it 'separates assignment and course scopes with the same numeric parent ID' do
      shared_id = ([Assignment.maximum(:id), Course.maximum(:id)].compact.max || 0) + 1
      assignment = create_parent(:assignment, id: shared_id)
      course = create_parent(:course, id: shared_id)
      assignment_team = create_team(assignment)
      course_team = create_team(course)
      assignment_member = create_participant(assignment)
      course_member = create_participant(course)
      create_membership(assignment_team, assignment_member)
      create_membership(course_team, course_member)

      expect(assignment.teams).to contain_exactly(assignment_team)
      expect(course.teams).to contain_exactly(course_team)
      expect(assignment_team.participant_on_team?(course_member)).to be(false)
      expect(course_team.participant_on_team?(assignment_member)).to be(false)
    end
  end

  describe 'capacity' do
    it 'does not apply an unrelated assignment limit to a course with the same ID' do
      shared_id = ([Assignment.maximum(:id), Course.maximum(:id)].compact.max || 0) + 1
      create_parent(:assignment, id: shared_id, max_team_size: 1)
      course = create_parent(:course, id: shared_id)
      course_team = create_team(course)
      2.times { create_membership(course_team, create_participant(course)) }

      expect(course_team.max_size).to be_nil
      expect(course_team.full?).to be(false)
    end

    shared_examples 'assignment capacity lookup' do
      # Verifies the configured positive assignment limit supplies the team's maximum.
      it 'returns the assignment maximum' do
        parent = create_parent(:assignment, max_team_size: 4)
        team = create_team(parent, klass: team_class)

        expect(team.max_size).to eq(4)
      end
    end

    [AssignmentTeam, MentoredTeam].each do |klass|
      context "for #{klass}" do
        let(:team_class) { klass }
        include_examples 'assignment capacity lookup'
      end
    end

    { 1 => false, 2 => true }.each do |member_count, expected_full|
      # Verifies the positive capacity boundary below and exactly at the allowed membership.
      it "reports full? as #{expected_full} for #{member_count} members at capacity two" do
        parent = create_parent(:assignment, max_team_size: 2)
        team = create_team(parent)
        member_count.times { create_membership(team, create_participant(parent)) }

        expect(team.full?).to be(expected_full)
      end
    end

    # Verifies lowering a positive limit preserves existing members but prevents further admission.
    it 'treats a team as full after its assignment limit is lowered below membership' do
      parent = create_parent(:assignment, max_team_size: 3)
      team = create_team(parent)
      members = Array.new(3) { create_participant(parent) }
      members.each { |member| create_membership(team, member) }
      candidate = create_participant(parent)
      parent.update!(max_team_size: 2)
      team.reload

      expect(team.full?).to be(true)
      expect(team.add_member(candidate).fetch(:success)).to be(false)
      expect(team.participants).to match_array(members)
    end

    # Verifies course teams use their separate default policy without an assignment capacity limit.
    it 'does not report a populated course team as full' do
      parent = create_parent(:course)
      team = create_team(parent)
      2.times { create_membership(team, create_participant(parent)) }

      expect(team.full?).to be(false)
    end

    # Verifies a new participant is rejected when a positive assignment limit is reached.
    it 'rejects admission to an exactly full assignment team' do
      parent = create_parent(:assignment, max_team_size: 1)
      team = create_team(parent)
      member = create_participant(parent)
      candidate = create_participant(parent)
      create_membership(team, member)
      result = nil

      expect { result = team.add_member(candidate) }.not_to change(TeamsParticipant, :count)

      expect(result.fetch(:success)).to be(false)
      expect(team.participants).to contain_exactly(member)
    end

    # Verifies participant eligibility remains distinct from capacity enforcement during admission.
    it 'considers a participant without a team eligible even when the team is full' do
      parent = create_parent(:assignment, max_team_size: 1)
      team = create_team(parent)
      create_membership(team, create_participant(parent))
      candidate = create_participant(parent)

      expect(team.full?).to be(true)
      expect(team.can_participant_join_team?(candidate)).to eq(success: true)
    end
  end

  describe 'failure boundaries' do
    let(:parent) { create_parent(:assignment) }
    let(:team) { create_team(parent) }
    let(:participant) { create_participant(parent) }

    # Verifies a membership created after the precheck yields a validation failure rather than a duplicate.
    it 'reports a rejected membership insert using its real validation errors' do
      candidate = participant
      target = team
      rejected_join = nil
      # Deterministically simulate an insert between the duplicate precheck and creation.
      allow(TeamsParticipant).to receive(:create).and_wrap_original do |original, attributes|
        TeamsParticipant.create!(attributes)
        rejected_join = original.call(attributes)
      end

      result = target.add_member(candidate)

      expect(result.fetch(:success)).to be(false)
      expect(rejected_join.errors.of_kind?(:participant_id, :taken)).to be(true)
      rejected_join.errors.full_messages.each do |message|
        expect(result.fetch(:error)).to include(message)
      end
      expect(target.teams_participants.pluck(:participant_id, :user_id)).to eq(
        [[candidate.id, candidate.user_id]]
      )
    end

    # Verifies a database insertion error becomes a failed admission without creating membership.
    it 'returns a failure result when membership persistence raises' do
      candidate = participant
      target = team
      failure = ActiveRecord::StatementInvalid.new('Membership insert unavailable')
      allow(TeamsParticipant).to receive(:create).and_raise(failure)
      result = nil

      expect { result = target.add_member(candidate) }.not_to change(TeamsParticipant, :count)

      expect(result).to eq(success: false, error: failure.message)
      expect(target.participants).to be_empty
    end

    # Verifies an exceptional invitation-cleanup failure leaves the member and team intact.
    it 'preserves membership when invitation retraction raises a database error' do
      membership = create_membership(team, participant)
      allow(participant).to receive(:retract_sent_invitations).and_raise(ActiveRecord::StatementInvalid)

      expect { team.remove_member(participant) }.to raise_error(ActiveRecord::StatementInvalid)

      expect(TeamsParticipant.exists?(membership.id)).to be(true)
      expect(team.reload.participants).to contain_exactly(participant)
    end
  end

  describe 'dependent record ownership' do
    # Verifies team deletion removes its dependent records while preserving people, parent and topic.
    it 'destroys dependent memberships, signups and requests without destroying their related entities' do
      parent = create_parent(:assignment)
      team = create_team(parent)
      participant = create_participant(parent)
      user = participant.user
      membership = create_membership(team, participant)
      legacy_join = TeamsUser.create!(team: team, user: user)
      topic = create_topic(parent)
      signup = SignedUpTeam.create!(team: team, project_topic: topic, is_waitlisted: false)
      request = JoinTeamRequest.create!(team: team, participant: participant, reply_status: 'PENDING')

      team.destroy!

      expect(Team.exists?(team.id)).to be(false)
      [membership, legacy_join, signup, request].each do |record|
        expect(record.class.exists?(record.id)).to be(false)
      end
      [parent, user, participant, topic].each do |record|
        expect(record.class.exists?(record.id)).to be(true)
      end
    end
  end

  describe 'topic release on team update' do
    let(:parent) { create_parent(:assignment) }
    let(:team) { create_team(parent) }
    let(:participant) { create_participant(parent) }
    let(:topic) { create_topic(parent) }

    # Verifies an ordinary populated-team rename preserves its topic allocation.
    it 'preserves signup when members remain during an update' do
      create_membership(team, participant)
      signup = SignedUpTeam.create!(team: team, project_topic: topic, is_waitlisted: false)

      team.update!(name: unique_name('renamed_team'))

      expect(signup.reload.is_waitlisted).to be(false)
      expect(team.reload.project_topics).to contain_exactly(topic)
    end

    # Verifies updating a team left empty by direct membership deletion releases its signup.
    it 'releases signup on a later update after direct removal leaves the team empty' do
      membership = create_membership(team, participant)
      signup = SignedUpTeam.create!(team: team, project_topic: topic, is_waitlisted: false)
      membership.destroy!

      team.update!(name: unique_name('renamed_team'))

      expect(SignedUpTeam.exists?(signup.id)).to be(false)
      expect(team.reload.project_topics).to be_empty
      expect(ProjectTopic.exists?(topic.id)).to be(true)
      expect(Participant.exists?(participant.id)).to be(true)
    end
  end
end
