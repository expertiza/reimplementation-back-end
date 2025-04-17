# spec/models/signed_up_team_spec.rb
require 'rails_helper'

RSpec.describe SignedUpTeam, type: :model do
  # Setup roles, users, assignment, topic and team to be reused across tests
  let!(:role) { Role.find_or_create_by!(name: "Instructor") }
  let!(:student_role) { Role.find_or_create_by!(name: "Student") }

  let!(:instructor) do
    User.create!(
      name: "test_instructor",
      full_name: "Test Instructor",
      password: "password",
      email: "instructor@example.com",
      role: role
    )
  end

  let!(:assignment) { Assignment.create!(name: "Test Assignment", instructor: instructor) }
  let!(:project_topic) { ProjectTopic.create!(topic_name: "Test Topic", assignment: assignment) }
  let!(:team) { Team.create!(assignment: assignment) }

  describe 'validations' do
    # Ensure a project_topic is mandatory
    it 'requires a project topic' do
      sut = SignedUpTeam.new(team: team)
      expect(sut).not_to be_valid
      expect(sut.errors[:project_topic]).to include("must exist")
    end

    # Ensure a team is mandatory
    it 'requires a team' do
      sut = SignedUpTeam.new(project_topic: project_topic)
      expect(sut).not_to be_valid
      expect(sut.errors[:team]).to include("must exist")
    end

    # Ensure uniqueness of team per project_topic
    it 'enforces unique team per project topic' do
      SignedUpTeam.create!(project_topic: project_topic, team: team)
      duplicate = SignedUpTeam.new(project_topic: project_topic, team: team)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:team]).to include("has already been taken")
    end
  end

  describe 'scopes' do
    # Create one confirmed and one waitlisted signup for testing scopes
    let!(:confirmed_signup) { SignedUpTeam.create!(project_topic: project_topic, team: team, is_waitlisted: false) }
    let!(:waitlisted_signup) { SignedUpTeam.create!(project_topic: project_topic, team: Team.create!(assignment: assignment), is_waitlisted: true) }

    # Scope should only return confirmed signups
    it 'returns confirmed signups' do
      expect(SignedUpTeam.confirmed).to contain_exactly(confirmed_signup)
    end

    # Scope should only return waitlisted signups
    it 'returns waitlisted signups' do
      expect(SignedUpTeam.waitlisted).to contain_exactly(waitlisted_signup)
    end
  end

  describe 'signup_for_topic' do
    # Should delegate logic to ProjectTopic's signup_team
    it 'delegates to project topic signup' do
      allow(project_topic).to receive(:signup_team).with(team).and_return(true)
      result = SignedUpTeam.signup_for_topic(team, project_topic)
      expect(result).to be true
      expect(project_topic).to have_received(:signup_team).with(team)
    end

    # Should return false if ProjectTopic rejects the signup
    it 'returns false if topic rejects signup' do
      allow(project_topic).to receive(:signup_team).with(team).and_return(false)
      result = SignedUpTeam.signup_for_topic(team, project_topic)
      expect(result).to be false
    end
  end

  describe 'remove_team_signups' do
    # Setup two topics and signups for deletion tests
    let!(:topic1) { ProjectTopic.create!(topic_name: "Topic 1", assignment: assignment) }
    let!(:topic2) { ProjectTopic.create!(topic_name: "Topic 2", assignment: assignment) }
    let!(:signup1) { SignedUpTeam.create!(project_topic: topic1, team: team) }
    let!(:signup2) { SignedUpTeam.create!(project_topic: topic2, team: team) }

    # Should remove all signups for the team across all topics
    it 'removes all team signups across topics' do
      expect {
        SignedUpTeam.remove_team_signups(team)
      }.to change(SignedUpTeam, :count).by(-2)
    end

    # Should not error if team has no signups
    it 'does not raise error if team has no signups' do
      new_team = Team.create!(assignment: assignment)
      expect { SignedUpTeam.remove_team_signups(new_team) }.not_to raise_error
    end
  end

  describe 'custom methods' do
    # Create test users to populate team
    let!(:user1) do
      User.create!(
        name: "Alice",
        full_name: "Alice Wonderland",
        password: "password",
        email: "alice@example.com",
        role: student_role
      )
    end

    let!(:user2) do
      User.create!(
        name: "Bob",
        full_name: "Bob Builder",
        password: "password",
        email: "bob@example.com",
        role: student_role
      )
    end

    before do
      team.users << [user1, user2]
    end

    describe '.find_team_participants' do
      # Should return users of a valid team
      it 'returns all users in a given team' do
        participants = SignedUpTeam.find_team_participants(team.id)
        expect(participants).to contain_exactly(user1, user2)
      end

      # Invalid team_id should return []
      it 'returns empty array if team does not exist' do
        expect(SignedUpTeam.find_team_participants(-1)).to eq([])
      end

      # Team with no users should return []
      it 'returns empty array when team exists but has no users' do
        new_team = Team.create!(assignment: assignment)
        expect(SignedUpTeam.find_team_participants(new_team.id)).to eq([])
      end
    end

    describe '.find_team_users' do
      let!(:sut) { SignedUpTeam.create!(project_topic: project_topic, team: team) }

      # Should return users if team is signed up
      it 'returns users in the team that signed up' do
        users = SignedUpTeam.find_team_users(team.id)
        expect(users).to contain_exactly(user1, user2)
      end

      # Should return [] if team is not signed up
      it 'returns empty array if no signed up team found' do
        new_team = Team.create!(assignment: assignment)
        expect(SignedUpTeam.find_team_users(new_team.id)).to eq([])
      end

      # Gracefully handle nil
      it 'handles nil team_id gracefully' do
        expect(SignedUpTeam.find_team_users(nil)).to eq([])
      end
    end

    describe '.find_user_signup_topics' do
      let!(:sut) { SignedUpTeam.create!(project_topic: project_topic, team: team) }

      # Returns topics signed up by any of the user’s teams
      it 'returns topics signed up by user’s team' do
        topics = SignedUpTeam.find_user_signup_topics(user1.id)
        expect(topics).to include(project_topic)
      end

      # Should return empty array for unknown user
      it 'returns empty array if user has no teams or no signups' do
        unknown = User.create!(
          name: "Ghost",
          full_name: "Ghost User",
          password: "password",
          email: "ghost@example.com",
          role: student_role
        )
        expect(SignedUpTeam.find_user_signup_topics(unknown.id)).to eq([])
      end

      # Gracefully handle nil user_id
      it 'handles nil user_id gracefully' do
        expect(SignedUpTeam.find_user_signup_topics(nil)).to eq([])
      end

      # Should work even if user is part of multiple teams
      it 'handles user with multiple teams' do
        team2 = Team.create!(assignment: assignment)
        team2.users << user1
        SignedUpTeam.create!(project_topic: project_topic, team: team2)
        topics = SignedUpTeam.find_user_signup_topics(user1.id)
        expect(topics).to include(project_topic)
      end
    end
  end

  describe 'functional behavior' do
    # Should create a record on successful signup
    it 'creates a record when signup_for_topic succeeds' do
      expect {
        SignedUpTeam.signup_for_topic(team, project_topic)
      }.to change { SignedUpTeam.count }.by(1)
    end

    # Should prevent duplicate signups
    it 'does not create a duplicate signup' do
      SignedUpTeam.signup_for_topic(team, project_topic)
      expect {
        SignedUpTeam.signup_for_topic(team, project_topic)
      }.not_to change { SignedUpTeam.count }
    end

    # Ensure cleanup removes all records
    it 'remove_team_signups deletes all signups for team' do
      topic1 = ProjectTopic.create!(topic_name: "Another Topic", assignment: assignment)
      topic2 = ProjectTopic.create!(topic_name: "Third Topic", assignment: assignment)
      SignedUpTeam.signup_for_topic(team, topic1)
      SignedUpTeam.signup_for_topic(team, topic2)

      expect {
        SignedUpTeam.remove_team_signups(team)
      }.to change { SignedUpTeam.count }.by(-2)
    end

    # Scopes should work correctly with multiple signups
    it 'confirmed and waitlisted scopes handle multiple entries' do
      confirmed = SignedUpTeam.create!(project_topic: project_topic, team: team, is_waitlisted: false)
      waitlisted = SignedUpTeam.create!(
        project_topic: ProjectTopic.create!(topic_name: "Waitlist Topic", assignment: assignment),
        team: Team.create!(assignment: assignment),
        is_waitlisted: true
      )
      expect(SignedUpTeam.confirmed).to include(confirmed)
      expect(SignedUpTeam.waitlisted).to include(waitlisted)
    end
  end
end
