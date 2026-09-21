# frozen_string_literal: true

require 'rails_helper'

# This spec exercises the Team model, covering:
#  - Presence and inclusion validations on parent_id and STI type
#  - The full? method, which determines if a team has reached capacity
#  - The can_participant_join_team? method, which enforces eligibility rules
#  - The add_member method, which creates TeamsParticipant records
#  - Membership queries, removal, and topic release after updates
RSpec.describe Team, type: :model do
  include RolesHelper
  # --------------------------------------------------------------------------
  # Global Setup
  # --------------------------------------------------------------------------
  # Create the roles hierarchy before each example, within test isolation.
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

  # Establish membership independently of add_member so setup cannot hide its defects.
  def link_member(team, participant)
    TeamsParticipant.create!(team: team, participant: participant, user: participant.user)
  end

  def register_participant(klass, parent, suffix)
    user = create_student(suffix)
    klass.create!(parent_id: parent.id, user: user, handle: user.name)
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

  let(:team_owner) do
    User.create!(
      name:            "team_owner",
      full_name:       "Team Owner",
      email:           "team_owner@example.com",
      password_digest: "password",
      role_id:          @roles[:student].id,
      institution_id:  institution.id
    )
  end

  # Two assignments with explicit max_team_size values, for testing AssignmentTeam.full?
  let(:assignment)  { Assignment.create!(name: "Assignment 1", instructor_id: instructor.id, max_team_size: 3) }
  let(:assignment2) { Assignment.create!(name: "Assignment 2", instructor_id: instructor.id, max_team_size: 2) }

  # Two courses (Course model does not have max_team_size column)
  let(:course)  { Course.create!(name: "Course 1", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course1") }
  let(:course2) { Course.create!(name: "Course 2", instructor_id: instructor.id, institution_id: institution.id, directory_path: "/course2") }

  # ------------------------------------------------------------------------
  # Create one team per context using STI subclasses
  # ------------------------------------------------------------------------
  let(:assignment_team) do
    AssignmentTeam.create!(
      parent_id:      assignment.id,
      name:           'team 1',
    )
  end

  let(:course_team) do
    CourseTeam.create!(
      parent_id:      course.id,
      name:           'team 2',
    )
  end

  # ------------------------------------------------------------------------
  # Validation Tests
  #
  # Ensure presence of parent_id and type, and correct inclusion for STI.
  # ------------------------------------------------------------------------
  describe 'validations' do
    it 'is invalid without parent_id' do
      # Missing parent_id should trigger a blank error on the parent_id column.
      team = Team.new(type: 'AssignmentTeam')
      expect(team).not_to be_valid
      expect(team.errors[:parent_id]).to include("can't be blank")
    end

    it 'is invalid without type' do
      # Missing STI type should trigger a blank error on the type column.
      team = Team.new(parent_id: assignment.id)
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("can't be blank")
    end

    it 'is invalid with incorrect type' do
      # An unsupported value for type should trigger an inclusion error.
      team = Team.new(parent_id: assignment.id, type: 'Team')
      expect(team).not_to be_valid
      expect(team.errors[:type]).to include("must be 'Assignment' or 'Course' or 'Mentor'")
    end

    it 'is valid as AssignmentTeam' do
      # Correct STI subclass automatically sets type = 'AssignmentTeam'
      expect(assignment_team).to be_valid
    end

    it 'is valid as CourseTeam' do
      # Correct STI subclass automatically sets type = 'CourseTeam'
      expect(course_team).to be_valid
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #full?
  #
  # AssignmentTeam: compares participants.count to assignment.max_team_size.
  # CourseTeam: always returns false (no cap).
  # ------------------------------------------------------------------------
  describe '#full?' do
    it 'returns true when participants count equals assignment.max_team_size' do
      # Seed exactly max_team_size participants into the assignment_team.
      3.times do |i|
        user        = create_student("student#{i}")
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        assignment_team.id,
          user_id:        user.id
        )
      end

      assignment_team.reload
      expect(assignment_team.participants.count).to eq(3)
      expect(assignment_team.full?).to be true
    end

    it 'returns false when participants count < assignment.max_team_size' do
      # A team one place below capacity must still accept another participant.
      2.times do |i|
        link_member(assignment_team, register_participant(AssignmentParticipant, assignment, "below#{i}"))
      end
      expect(assignment_team.full?).to be false
    end

    it 'returns true above capacity' do
      # Protects the greater-than branch: equality-only capacity checks are insufficient.
      4.times do |i|
        link_member(assignment_team, register_participant(AssignmentParticipant, assignment, "above#{i}"))
      end
      expect(assignment_team.full?).to be true
    end

    it 'returns false when assignment capacity is unset' do
      # A nullable capacity uses the explicit unlimited fallback.
      assignment.update!(max_team_size: nil)
      expect(assignment_team.full?).to be false
    end

    it 'returns true for an empty assignment team with zero capacity' do
      # Zero is a configured limit, so even zero members meet that limit.
      assignment.update!(max_team_size: 0)
      expect(assignment_team.full?).to be true
    end

    it 'always returns false for a CourseTeam (no capacity limit)' do
      # Seed multiple participants into the course_team.
      5.times do |i|
        user        = create_student("cstudent#{i}")
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        course_team.id,
          user_id:        user.id
        )
      end

      course_team.reload
      expect(course_team.full?).to be false
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #can_participant_join_team?
  #
  # Ensures a participant:
  #  - Cannot join if already on any team in the same context
  #  - Cannot join if not registered in that assignment/course
  #  - Can join otherwise
  # ------------------------------------------------------------------------
  describe '#can_participant_join_team?' do
    context 'AssignmentTeam context' do
      it 'rejects a participant already on a team' do
        # Existing membership must block eligibility even when the participant is registered here.
        user        = create_student("student_team")
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        assignment_team.id,
          user_id:        user.id
        )

        result = assignment_team.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/already assigned/)
      end

      it 'rejects a participant registered under a different assignment' do
        # Registration in another assignment must not satisfy this assignment's enrollment check.
        user        = create_student("wrong_assignment")
        participant = AssignmentParticipant.create!(parent_id: assignment2.id, user: user, handle: user.name)

        result = assignment_team.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/not a participant/)
      end

      it 'allows a properly registered, not-yet-teamed participant' do
        # A registered participant without a team must pass the assignment eligibility checks.
        user        = create_student("eligible")
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)

        result = assignment_team.can_participant_join_team?(participant)
        expect(result[:success]).to be true
      end
    end

    context 'CourseTeam context' do
      it 'rejects a participant already on a course team' do
        # Course eligibility must reject an existing member, just as assignment eligibility does.
        user        = create_student("course_user")
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)
        TeamsParticipant.create!(
          participant_id: participant.id,
          team_id:        course_team.id,
          user_id:        user.id
        )

        result = course_team.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/already assigned/)
      end

      it 'rejects a participant registered under a different course' do
        # Course registration is scoped to the parent; enrollment elsewhere is insufficient.
        user        = create_student("wrong_course")
        participant = CourseParticipant.create!(parent_id: course2.id, user: user, handle: user.name)

        result = course_team.can_participant_join_team?(participant)
        expect(result[:success]).to be false
        expect(result[:error]).to match(/not a participant/)
      end

      it 'allows a properly registered, not-yet-teamed course participant' do
        # Protects the successful course eligibility path for an enrolled, unteamed participant.
        user        = create_student("c_eligible")
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)

        result = course_team.can_participant_join_team?(participant)
        expect(result[:success]).to be true
      end
    end
  end

  # ------------------------------------------------------------------------
  # Tests for #add_member
  #
  # AssignmentTeam:
  #   - Should create a TeamsParticipant record when capacity allows
  #   - Should return an error when at capacity
  # CourseTeam:
  #   - Should always add (unless manually overridden, but model does not cap)
  # ------------------------------------------------------------------------
  describe '#add_member' do
    context 'AssignmentTeam' do
      it 'creates a TeamsParticipant record on success' do
        # Verify the return contract and member identity, not just an arbitrary new row.
        user        = create_student("add_user")
        participant = AssignmentParticipant.create!(parent_id: assignment.id, user: user, handle: user.name)

        result = nil
        expect {
          result = assignment_team.add_member(participant)
        }.to change { TeamsParticipant.where(team_id: assignment_team.id).count }.by(1)
        expect(result).to eq(success: true)
        expect(TeamsParticipant.find_by!(team: assignment_team, participant: participant).user_id).to eq(user.id)
      end

      it 'returns an error if the assignment team is already full' do
        # Establish capacity independently, then verify rejection has no membership side effect.
        3.times do |i|
          user_i   = create_student("f#{i}")
          part_i   = AssignmentParticipant.create!(parent_id: assignment.id, user: user_i, handle: user_i.name)
          link_member(assignment_team, part_i)
        end

        extra_user = create_student("f_extra")
        extra_part = AssignmentParticipant.create!(parent_id: assignment.id, user: extra_user, handle: extra_user.name)
        expect(assignment_team.participants.count).to eq(3)
        result = nil
        expect {
          result = assignment_team.add_member(extra_part)
        }.not_to change { assignment_team.teams_participants.reload.pluck(:id) }
        expect(result).to eq(success: false, error: "Unable to add participant: team is at full capacity.")
        expect(assignment_team.participants.exists?(extra_part.id)).to be false
      end
    end

    context 'CourseTeam' do
      it 'creates a TeamsParticipant record on success' do
        # Course addition must persist the intended participant/user and report success.
        user        = create_student("cadd")
        participant = CourseParticipant.create!(parent_id: course.id, user: user, handle: user.name)
        
        result = nil
        expect {
          result = course_team.add_member(participant)
        }.to change { TeamsParticipant.where(team_id: course_team.id).count }.by(1)
        expect(result).to eq(success: true)
        expect(TeamsParticipant.find_by!(team: course_team, participant: participant).user_id).to eq(user.id)
      end

      it 'still adds even if max_participants is manually set (no cap by default)' do
        # Verify two persisted members despite the accessor, rather than an unchecked first addition.
        course_team.max_participants = 1

        first_user = create_student("cf1")
        first_part = CourseParticipant.create!(parent_id: course.id, user: first_user, handle: first_user.name)
        link_member(course_team, first_part)

        second_user = create_student("cf2")
        second_part = CourseParticipant.create!(parent_id: course.id, user: second_user, handle: second_user.name)
        result      = course_team.add_member(second_part)

        # CourseTeam.full? is false, so add_member should succeed
        expect(result[:success]).to be true
        expect(course_team.participants.reload.pluck(:id)).to contain_exactly(first_part.id, second_part.id)
      end
    end
  end

  describe '#has_member?' do
    it 'recognizes a linked user and excludes a user belonging only to another team' do
      # Protects both user-identity lookup and isolation from another team's membership.
      member = register_participant(AssignmentParticipant, assignment, 'member')
      outsider = register_participant(AssignmentParticipant, assignment, 'outsider')
      other_team = AssignmentTeam.create!(assignment: assignment, name: 'Other team')
      link_member(assignment_team, member)
      link_member(other_team, outsider)

      expect(assignment_team.has_member?(member.user)).to be true
      expect(assignment_team.has_member?(outsider.user)).to be false
    end
  end

  describe '#team_size' do
    it 'returns zero for an empty team' do
      # Exercises the model's public count, which the serializer does not call.
      expect(assignment_team.team_size).to eq(0)
    end

    it 'counts only users linked to this team' do
      # Multiple members and an unrelated team expose constant or unscoped counts.
      2.times do |i|
        link_member(assignment_team, register_participant(AssignmentParticipant, assignment, "count#{i}"))
      end
      other_team = AssignmentTeam.create!(assignment: assignment, name: 'Other team')
      link_member(other_team, register_participant(AssignmentParticipant, assignment, 'other_count'))

      expect(assignment_team.team_size).to eq(2)
    end
  end

  describe '#max_size' do
    it 'returns the assignment capacity' do
      # A second assignment with a different limit prevents use of a global/default value.
      other_team = AssignmentTeam.create!(assignment: assignment2, name: 'Other team')
      expect(assignment_team.max_size).to eq(3)
      expect(other_team.max_size).to eq(2)
    end

    it 'returns nil when assignment capacity is unset' do
      # Preserves the explicit fallback for the nullable parent capacity.
      assignment.update!(max_team_size: nil)
      expect(assignment_team.max_size).to be_nil
    end
  end

  # Both contexts use Team's implementation but select different parent scopes and STI classes.
  [[:assignment_team, :assignment, :assignment2, AssignmentParticipant, AssignmentTeam, 'assignment'],
   [:course_team, :course, :course2, CourseParticipant, CourseTeam, 'course']].each do |team_fixture, parent_fixture, other_parent_fixture, participant_class, team_class, label|
    context "#{label} membership scoping" do
      let(:target_team) { public_send(team_fixture) }
      let(:parent) { public_send(parent_fixture) }
      let(:other_parent) { public_send(other_parent_fixture) }

      it 'adds a User through the registration belonging to the target context' do
        # Create the wrong-context registration first to detect an unscoped find_by.
        user = create_student('multiple_registrations')
        other_participant = participant_class.create!(user: user, parent_id: other_parent.id, handle: user.name)
        participant = participant_class.create!(user: user, parent_id: parent.id, handle: user.name)
        result = nil

        expect {
          result = target_team.add_member(user)
        }.to change { TeamsParticipant.where(team_id: target_team.id).count }.by(1)
        expect(result).to eq(success: true)
        membership = TeamsParticipant.find_by!(team: target_team, participant: participant)
        expect(membership.user_id).to eq(user.id)
        expect(target_team.participants.exists?(other_participant.id)).to be false
      end

      it 'rejects an existing member without changing their membership' do
        # The specific error distinguishes Team's duplicate guard from join validation failure.
        participant = register_participant(participant_class, parent, 'duplicate')
        membership = link_member(target_team, participant)
        result = nil

        expect {
          result = target_team.add_member(participant)
        }.not_to change { target_team.teams_participants.reload.pluck(:id) }
        expect(result).to eq(success: false, error: 'Participant already on the team')
        expect(TeamsParticipant.exists?(membership.id)).to be true
      end

      it 'rejects eligibility when the participant belongs to a sibling team' do
        # A check limited to the target team would incorrectly allow this participant.
        participant = register_participant(participant_class, parent, 'sibling_member')
        sibling = team_class.create!(parent_id: parent.id, name: 'Sibling')
        link_member(sibling, participant)

        expect(target_team.can_participant_join_team?(participant)).to eq(
          success: false, error: "This user is already assigned to a team for this #{label}"
        )
      end

      it 'allows eligibility when the user is teamed only in another parent context' do
        # Registration and membership elsewhere must not block the target registration.
        user = create_student('other_context_member')
        other_participant = participant_class.create!(user: user, parent_id: other_parent.id, handle: user.name)
        other_team = team_class.create!(parent_id: other_parent.id, name: 'Other context')
        link_member(other_team, other_participant)
        participant = participant_class.create!(user: user, parent_id: parent.id, handle: user.name)

        expect(target_team.can_participant_join_team?(participant)).to eq(success: true)
      end
    end
  end

  describe '#add_member failures' do
    let(:participant) { register_participant(AssignmentParticipant, assignment, 'failed_add') }

    it 'returns all validation messages when the join cannot be persisted' do
      # Isolate Team's error translation without inventing invalid persisted domain records.
      failed_join = TeamsParticipant.new
      failed_join.errors.add(:base, 'First problem')
      failed_join.errors.add(:base, 'Second problem')
      allow(TeamsParticipant).to receive(:create).with(
        participant_id: participant.id, team_id: assignment_team.id, user_id: participant.user_id
      ).and_return(failed_join)
      result = nil

      expect {
        result = assignment_team.add_member(participant)
      }.not_to change(TeamsParticipant, :count)
      expect(result).to eq(success: false, error: 'First problem, Second problem')
    end

    it 'converts a membership creation exception into a failure result' do
      # A controlled collaborator failure verifies the rescue contract without adapter-specific errors.
      allow(TeamsParticipant).to receive(:create).with(
        participant_id: participant.id, team_id: assignment_team.id, user_id: participant.user_id
      ).and_raise(StandardError, 'membership write failed')
      result = nil

      expect {
        result = assignment_team.add_member(participant)
      }.not_to change(TeamsParticipant, :count)
      expect(result).to eq(success: false, error: 'membership write failed')
    end
  end

  describe '#remove_member' do
    it 'removes only the requested member and preserves a nonempty team' do
      # Removal must delete the join, not the participant/user or the remaining membership.
      participant = register_participant(CourseParticipant, course, 'removed')
      remaining = register_participant(CourseParticipant, course, 'remaining')
      removed_join = link_member(course_team, participant)
      retained_join = link_member(course_team, remaining)

      course_team.remove_member(participant)

      expect(TeamsParticipant.exists?(removed_join.id)).to be false
      expect(TeamsParticipant.exists?(retained_join.id)).to be true
      expect(Team.exists?(course_team.id)).to be true
      expect(Participant.exists?(participant.id)).to be true
      expect(User.exists?(participant.user_id)).to be true
    end

    it 'clears the stored team reference and destroys the team after its last member leaves' do
      # CourseParticipant reads the stored team_id; clearing it also permits team deletion under its FK.
      participant = register_participant(CourseParticipant, course, 'last_member')
      membership = link_member(course_team, participant)
      participant.update!(team_id: course_team.id)

      course_team.remove_member(participant)

      expect(TeamsParticipant.exists?(membership.id)).to be false
      expect(Team.exists?(course_team.id)).to be false
      expect(participant.reload[:team_id]).to be_nil
      expect(User.exists?(participant.user_id)).to be true
    end

    it 'preserves another team membership and its stored team reference' do
      # Both the join lookup and legacy-reference update must be scoped to the team being left.
      participant = register_participant(CourseParticipant, course, 'shared_member')
      other_team = CourseTeam.create!(course: course, name: 'Other team')
      removed_join = link_member(course_team, participant)
      retained_join = link_member(other_team, participant)
      participant.update!(team_id: other_team.id)

      course_team.remove_member(participant)

      expect(TeamsParticipant.exists?(removed_join.id)).to be false
      expect(TeamsParticipant.exists?(retained_join.id)).to be true
      expect(participant.reload[:team_id]).to eq(other_team.id)
      expect(Team.exists?(other_team.id)).to be true
    end

    it 'retracts a sent invitation when removing an assignment participant' do
      # One real invitation verifies removal's integration with retraction, not invitation internals.
      participant = register_participant(AssignmentParticipant, assignment, 'inviter')
      remaining = register_participant(AssignmentParticipant, assignment, 'staying')
      invitee = register_participant(AssignmentParticipant, assignment, 'invitee')
      membership = link_member(assignment_team, participant)
      link_member(assignment_team, remaining)
      invitation = Invitation.create!(assignment: assignment, from_id: participant.id,
                                      to_id: invitee.id, reply_status: InvitationValidator::WAITING_STATUS)

      assignment_team.remove_member(participant)

      expect(invitation.reload.reply_status).to eq(InvitationValidator::RETRACT_STATUS)
      expect(TeamsParticipant.exists?(membership.id)).to be false
      expect(Team.exists?(assignment_team.id)).to be true
    end
  end

  describe 'topic release after update' do
    let(:topic) { ProjectTopic.create!(assignment: assignment, topic_name: 'Topic', max_choosers: 2) }

    it 'releases all signups for an empty team while retaining topics and other teams' do
      # Use a public update to test callback wiring as well as release of every associated topic.
      second_topic = ProjectTopic.create!(assignment: assignment, topic_name: 'Second topic', max_choosers: 1)
      other_team = AssignmentTeam.create!(assignment: assignment, name: 'Other team')
      signups = [topic, second_topic].map do |project_topic|
        SignedUpTeam.create!(team: assignment_team, project_topic: project_topic, is_waitlisted: false)
      end
      retained_signup = SignedUpTeam.create!(team: other_team, project_topic: topic, is_waitlisted: false)

      assignment_team.update!(name: 'Renamed empty team')

      expect(SignedUpTeam.where(id: signups.map(&:id))).to be_empty
      expect(SignedUpTeam.exists?(retained_signup.id)).to be true
      expect(ProjectTopic.where(id: [topic.id, second_topic.id]).count).to eq(2)
      expect(Team.exists?(assignment_team.id)).to be true
    end

    it 'retains topic signups when a populated team is updated' do
      # Guards against releasing a topic merely because any team attribute changed.
      link_member(assignment_team, register_participant(AssignmentParticipant, assignment, 'topic_member'))
      signup = SignedUpTeam.create!(team: assignment_team, project_topic: topic, is_waitlisted: false)

      assignment_team.update!(name: 'Renamed populated team')

      expect(SignedUpTeam.exists?(signup.id)).to be true
      expect(assignment_team.reload.project_topics).to include(topic)
    end
  end
end
