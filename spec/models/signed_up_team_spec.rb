# spec/models/signed_up_team_spec.rb
require 'rails_helper'

RSpec.describe SignedUpTeam, type: :model do
  let!(:role) { Role.create!(name: "Instructor") }
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
  end
end