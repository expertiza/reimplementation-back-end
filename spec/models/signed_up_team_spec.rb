# spec/models/signed_up_team_spec.rb
require 'rails_helper'

RSpec.describe SignedUpTeam, type: :model do
  let!(:role) { Role.create!(name: "Instructor") }
  let!(:student_role) { Role.create!(name: "Student") }

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
    it 'requires a project topic' do
      sut = SignedUpTeam.new(team: team)
      expect(sut).not_to be_valid
      expect(sut.errors[:project_topic]).to include("must exist")
    end

    it 'requires a team' do
      sut = SignedUpTeam.new(project_topic: project_topic)
      expect(sut).not_to be_valid
      expect(sut.errors[:team]).to include("must exist")
    end

    it 'enforces unique team per project topic' do
      SignedUpTeam.create!(project_topic: project_topic, team: team)
      duplicate = SignedUpTeam.new(project_topic: project_topic, team: team)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:team]).to include("has already been taken")
    end
  end

  describe 'scopes' do
    let!(:confirmed_signup) { SignedUpTeam.create!(project_topic: project_topic, team: team, is_waitlisted: false) }
    let!(:waitlisted_signup) { SignedUpTeam.create!(project_topic: project_topic, team: Team.create!(assignment: assignment), is_waitlisted: true) }

    it 'returns confirmed signups' do
      expect(SignedUpTeam.confirmed).to contain_exactly(confirmed_signup)
    end

    it 'returns waitlisted signups' do
      expect(SignedUpTeam.waitlisted).to contain_exactly(waitlisted_signup)
    end
  end

  describe 'signup_for_topic' do
    it 'delegates to project topic signup' do
      allow(project_topic).to receive(:signup_team).with(team).and_return(true)
      result = SignedUpTeam.signup_for_topic(team, project_topic)
      expect(result).to be true
      expect(project_topic).to have_received(:signup_team).with(team)
    end

    it 'returns false if topic rejects signup' do
      allow(project_topic).to receive(:signup_team).with(team).and_return(false)
      result = SignedUpTeam.signup_for_topic(team, project_topic)
      expect(result).to be false
    end
  end

  describe 'remove_team_signups' do
    let!(:topic1) { ProjectTopic.create!(topic_name: "Topic 1", assignment: assignment) }
    let!(:topic2) { ProjectTopic.create!(topic_name: "Topic 2", assignment: assignment) }
    let!(:signup1) { SignedUpTeam.create!(project_topic: topic1, team: team) }
    let!(:signup2) { SignedUpTeam.create!(project_topic: topic2, team: team) }

    it 'removes all team signups across topics' do
      expect {
        SignedUpTeam.remove_team_signups(team)
      }.to change(SignedUpTeam, :count).by(-2)
    end

    it 'does not raise error if team has no signups' do
      new_team = Team.create!(assignment: assignment)
      expect { SignedUpTeam.remove_team_signups(new_team) }.not_to raise_error
    end
  end

  describe 'custom methods' do
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
      it 'returns all users in a given team' do
        participants = SignedUpTeam.find_team_participants(team.id)
        expect(participants).to contain_exactly(user1, user2)
      end

      it 'returns empty array if team does not exist' do
        expect(SignedUpTeam.find_team_participants(-1)).to eq([])
      end

      it 'returns empty array when team exists but has no users' do
        new_team = Team.create!(assignment: assignment)
        expect(SignedUpTeam.find_team_participants(new_team.id)).to eq([])
      end
    end

    describe '.find_team_users' do
      let!(:sut) { SignedUpTeam.create!(project_topic: project_topic, team: team) }

      it 'returns users in the team that signed up' do
        users = SignedUpTeam.find_team_users(team.id)
        expect(users).to contain_exactly(user1, user2)
      end

      it 'returns empty array if no signed up team found' do
        new_team = Team.create!(assignment: assignment)
        expect(SignedUpTeam.find_team_users(new_team.id)).to eq([])
      end

      it 'handles nil team_id gracefully' do
        expect(SignedUpTeam.find_team_users(nil)).to eq([])
      end
    end

    describe '.find_user_signup_topics' do
      let!(:sut) { SignedUpTeam.create!(project_topic: project_topic, team: team) }

      it 'returns topics signed up by user’s team' do
        topics = SignedUpTeam.find_user_signup_topics(user1.id)
        expect(topics).to include(project_topic)
      end

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

      it 'handles nil user_id gracefully' do
        expect(SignedUpTeam.find_user_signup_topics(nil)).to eq([])
      end

      it 'handles user with multiple teams' do
        team2 = Team.create!(assignment: assignment)
        team2.users << user1
        SignedUpTeam.create!(project_topic: project_topic, team: team2)
        topics = SignedUpTeam.find_user_signup_topics(user1.id)
        expect(topics).to include(project_topic)
      end
    end
  end
end
