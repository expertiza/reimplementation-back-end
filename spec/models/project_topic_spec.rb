require 'rails_helper'

RSpec.describe ProjectTopic, type: :model do
  let!(:role) { Role.find_or_create_by!(name: "Instructor") }
  let!(:instructor) do
    Instructor.create!(
      name: "test_instructor",
      password: "password",
      full_name: "Test Instructor",
      email: "instructor@example.com",
      role: role
    )
  end
  let!(:assignment) { Assignment.create!(name: "Test Assignment", instructor: instructor) }
  let!(:project_topic) { ProjectTopic.create!(topic_name: "Test Topic", assignment: assignment, max_choosers: 2) }
  # CHANGED: Updated to use AssignmentTeam instead of generic Team for proper validation (E2552)
  let!(:team) { AssignmentTeam.create!(assignment: assignment) }

  # CHANGED: Updated test description to reflect renamed method (E2552)
  describe '#sign_team_up' do
    context 'when slots are available' do
      it 'adds team as confirmed' do
        # This test verifies that a team is added as confirmed when slots are available.
        expect(project_topic.sign_team_up(team)).to be true
        expect(project_topic.confirmed_teams).to include(team)
      end

      it 'removes team from waitlist of other topics' do
        # This checks that a team signing up for one topic is removed from the waitlists of other topics.
        other_topic = ProjectTopic.create!(topic_name: "Other Topic", assignment: assignment, max_choosers: 1)
        other_topic.sign_team_up(team)
        project_topic.sign_team_up(team)
        expect(other_topic.reload.waitlisted_teams).not_to include(team)
      end
    end

    context 'when slots are full' do
      before do
        # Fill all slots before each test in this context.
        2.times { project_topic.sign_team_up(AssignmentTeam.create!(assignment: assignment)) }
      end

      it 'adds team to waitlist' do
        # When no slots are available, the team should be added to the waitlist.
        new_team = AssignmentTeam.create!(assignment: assignment)
        expect(project_topic.sign_team_up(new_team)).to be true
        expect(project_topic.waitlisted_teams).to include(new_team)
      end
    end

    context 'when team already signed up' do
      before { project_topic.sign_team_up(team) }
      it 'returns false' do
        # A team cannot sign up more than once. The method returns false if already signed up.
        expect(project_topic.sign_team_up(team)).to be false
      end
    end

    it 'does not raise exception when transaction fails' do
      # This test simulates an error in ActiveRecord and ensures the method handles it gracefully.
      allow(project_topic).to receive(:signed_up_teams).and_raise(ActiveRecord::RecordInvalid)
      expect(project_topic.sign_team_up(team)).to be false
    end
  end

  describe '#drop_team' do
    before { project_topic.sign_team_up(team) }

    it 'returns nil if team is not signed up' do
      # Verifies that dropping a team not signed up to the topic returns nil.
      new_team = AssignmentTeam.create!(assignment: assignment)
      expect(project_topic.drop_team(new_team)).to be_nil
    end

    it 'does not raise error for non-existent team' do
      # Ensures dropping a non-existent team doesn't raise an exception.
      phantom_team = double("Team", id: -1)
      expect { project_topic.drop_team(phantom_team) }.not_to raise_error
    end
  end

  describe '#available_slots' do
    it 'returns correct number of slots' do
      # Confirms available_slots returns the correct number after signups.
      expect(project_topic.available_slots).to eq(2)
      project_topic.sign_team_up(team)
      expect(project_topic.available_slots).to eq(1)
    end

    it 'returns 0 when full' do
      # Ensures it returns 0 when max_choosers is reached.
      2.times { project_topic.sign_team_up(AssignmentTeam.create!(assignment: assignment)) }
      expect(project_topic.available_slots).to eq(0)
    end
  end

  describe '#get_signed_up_teams' do
    it 'returns all signed up teams' do
      # Checks that all teams, both confirmed and waitlisted, are returned.
      teams = 3.times.map { AssignmentTeam.create!(assignment: assignment) }
      teams.each { |t| project_topic.sign_team_up(t) }
      expect(project_topic.get_signed_up_teams.pluck(:team_id)).to include(*teams.map(&:id))
    end

    it 'returns only SignedUpTeam records' do
      # Verifies that returned records are of the SignedUpTeam model.
      team1 = AssignmentTeam.create!(assignment: assignment)
      project_topic.sign_team_up(team1)
      expect(project_topic.get_signed_up_teams.first).to be_a(SignedUpTeam)
    end
  end

  describe '#slot_available?' do
    it 'returns true when slots are available' do
      # Confirms slot_available? returns true before topic is full.
      expect(project_topic.slot_available?).to be true
    end

    it 'returns false when no slots are left' do
      # Confirms slot_available? returns false once topic is full.
      2.times { project_topic.sign_team_up(AssignmentTeam.create!(assignment: assignment)) }
      expect(project_topic.slot_available?).to be false
    end
  end

  describe '#confirmed_teams' do
    it 'returns only confirmed teams' do
      # Verifies that confirmed_teams returns only those not waitlisted.
      project_topic.sign_team_up(team)
      expect(project_topic.confirmed_teams).to contain_exactly(team)
    end

    it 'returns empty array if no confirmed teams' do
      # Returns an empty array when no confirmed signups exist.
      expect(project_topic.confirmed_teams).to be_empty
    end
  end

  describe '#waitlisted_teams' do
    it 'returns waitlisted teams in order' do
      # Ensures waitlisted teams are returned in the order they were added.
      5.times { project_topic.sign_team_up(AssignmentTeam.create!(assignment: assignment)) }
      waitlisted = project_topic.waitlisted_teams
      expect(waitlisted.size).to eq(3)
      expect(waitlisted).to eq(waitlisted.sort_by(&:created_at))
    end

    it 'returns empty array if no waitlisted teams' do
      # Returns an empty array when no teams are waitlisted.
      expect(project_topic.waitlisted_teams).to eq([])
    end
  end

  describe 'validations' do
    it 'requires topic_name' do
      # Validates presence of topic_name field.
      topic = ProjectTopic.new(assignment: assignment, max_choosers: 1)
      expect(topic).not_to be_valid
      expect(topic.errors[:topic_name]).to include("can't be blank")
    end

    it 'requires non-negative integer for max_choosers' do
      # Validates that max_choosers is a non-negative number.
      topic = ProjectTopic.new(topic_name: "Invalid", assignment: assignment, max_choosers: -1)
      expect(topic).not_to be_valid
      expect(topic.errors[:max_choosers]).to include("must be greater than or equal to 0")
    end

    # CHANGED: Added new test case for zero max_choosers validation (E2552)
    it 'allows zero max_choosers for waitlist-only topics' do
      # Validates that max_choosers can be zero for waitlist-only topics.
      topic = ProjectTopic.new(topic_name: "Waitlist Only", assignment: assignment, max_choosers: 0)
      expect(topic).to be_valid
    end
  end

  describe 'functional checks' do
    it 'increases confirmed team count on signup' do
      # Ensures that the count of confirmed teams increases after signup.
      expect { project_topic.sign_team_up(team) }.to change { project_topic.confirmed_teams.count }.by(1)
    end

    it 'does not allow more than max_choosers confirmed teams' do
      # Confirms that additional teams beyond limit go to waitlist.
      t1 = AssignmentTeam.create!(assignment: assignment)
      t2 = AssignmentTeam.create!(assignment: assignment)
      t3 = AssignmentTeam.create!(assignment: assignment)
      project_topic.sign_team_up(t1)
      project_topic.sign_team_up(t2)
      project_topic.sign_team_up(t3)
      expect(project_topic.confirmed_teams.count).to eq(2)
      expect(project_topic.waitlisted_teams.count).to eq(1)
    end

    it 'removes team’s other waitlisted entries on confirmed signup' do
      # Ensures a confirmed team is removed from other topic waitlists.
      t = AssignmentTeam.create!(assignment: assignment)
      t1 = ProjectTopic.create!(topic_name: "Alt Topic", assignment: assignment, max_choosers: 0)
      t1.sign_team_up(t)
      expect(t1.waitlisted_teams).to include(t)
      project_topic.sign_team_up(t)
      expect(t1.reload.waitlisted_teams).not_to include(t)
    end

    it 'get_signed_up_teams includes waitlisted and confirmed teams' do
      # Validates that all signed-up teams, regardless of status, are returned.
      t1 = AssignmentTeam.create!(assignment: assignment)
      t2 = AssignmentTeam.create!(assignment: assignment)
      project_topic.sign_team_up(t1)
      project_topic.sign_team_up(t2)
      expect(project_topic.get_signed_up_teams.map(&:team_id)).to include(t1.id, t2.id)
    end

    it 'slot_available? reflects accurate state after signup and drop' do
      # Checks dynamic behavior of slot availability after signup and drop.
      t1 = AssignmentTeam.create!(assignment: assignment)
      t2 = AssignmentTeam.create!(assignment: assignment)
      project_topic.sign_team_up(t1)
      project_topic.sign_team_up(t2)
      expect(project_topic.slot_available?).to be false
      project_topic.drop_team(t1)
      expect(project_topic.slot_available?).to be true
    end

    it 'signed_up_team records are removed when team is dropped' do
      # Confirms that dropping a team deletes the associated record.
      project_topic.sign_team_up(team)
      expect { project_topic.drop_team(team) }.to change { SignedUpTeam.count }.by(-1)
    end

    it 'multiple topics maintain independent signups' do
      # Ensures that signups in one topic do not affect another topic.
      topic2 = ProjectTopic.create!(topic_name: "Topic 2", assignment: assignment, max_choosers: 1)
      team2 = AssignmentTeam.create!(assignment: assignment)
      project_topic.sign_team_up(team)
      topic2.sign_team_up(team2)
      expect(project_topic.confirmed_teams).to include(team)
      expect(topic2.confirmed_teams).to include(team2)
    end

    it 'promotes the earliest waitlisted team after dropping a confirmed one' do
      # Ensures that when a confirmed team is dropped, the earliest waitlisted is promoted.
      t1 = AssignmentTeam.create!(assignment: assignment)
      t2 = AssignmentTeam.create!(assignment: assignment)
      t3 = AssignmentTeam.create!(assignment: assignment)
      project_topic.sign_team_up(t1)
      project_topic.sign_team_up(t2)
      project_topic.sign_team_up(t3)
      expect(project_topic.waitlisted_teams.first).to eq(t3)
      project_topic.drop_team(t1)
      expect(project_topic.confirmed_teams).to include(t2, t3)
      expect(project_topic.waitlisted_teams).to be_empty
    end

    it 'does not increase available slots after promoting a waitlisted team' do
      # Verifies that slot count remains constant when a waitlisted team is promoted.
      t1 = AssignmentTeam.create!(assignment: assignment)
      t2 = AssignmentTeam.create!(assignment: assignment)
      t3 = AssignmentTeam.create!(assignment: assignment)
      project_topic.sign_team_up(t1)
      project_topic.sign_team_up(t2)
      project_topic.sign_team_up(t3)
      expect(project_topic.available_slots).to eq(0)
      project_topic.drop_team(t1)
      expect(project_topic.available_slots).to eq(0)
    end
  end
end
