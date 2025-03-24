# spec/models/project_topic_spec.rb
require 'rails_helper'

RSpec.describe ProjectTopic, type: :model do
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
  let!(:project_topic) { ProjectTopic.create!(topic_name: "Test Topic", assignment: assignment, max_choosers: 2) }
  let!(:team) { Team.create!(assignment: assignment) }

  describe '#signup_team' do
    context 'when slots are available' do
      it 'adds team as confirmed' do
        expect(project_topic.signup_team(team)).to be true
        expect(project_topic.confirmed_teams).to include(team)
      end

      it 'removes team from waitlist' do
        other_topic = ProjectTopic.create!(topic_name: "Other Topic", assignment: assignment, max_choosers: 1)
        other_topic.signup_team(team)
        project_topic.signup_team(team)
        expect(other_topic.reload.waitlisted_teams).not_to include(team)
      end
    end

    context 'when slots are full' do
      before do
        2.times do |n|
          t = Team.create!(assignment: assignment)
          project_topic.signup_team(t)
        end
      end

      it 'adds team to waitlist' do
        new_team = Team.create!(assignment: assignment)
        expect(project_topic.signup_team(new_team)).to be true
        expect(project_topic.waitlisted_teams).to include(new_team)
      end
    end

    context 'when team already signed up' do
      before { project_topic.signup_team(team) }
      it 'returns false' do
        expect(project_topic.signup_team(team)).to be false
      end
    end
  end

  describe '#drop_team' do
    before do
      project_topic.signup_team(team)
      project_topic.signup_team(Team.create!(assignment: assignment))
    end

    context 'when dropping confirmed team' do
      it 'promotes waitlisted team' do
        waitlisted_team = Team.create!(assignment: assignment)
        waitlisted_team2 = Team.create!(assignment: assignment)
        project_topic.signup_team(waitlisted_team)
        project_topic.signup_team(waitlisted_team2)
        expect {
          project_topic.drop_team(team)
        }.to change { project_topic.confirmed_teams.count }.by(0)
        expect(waitlisted_team.reload.signed_up_teams.first.is_waitlisted).to be false
        expect(project_topic.waitlisted_teams.first).to eq(waitlisted_team2)
      end
    end

    context 'when dropping waitlisted team' do
      it 'does not promote other teams' do
        waitlisted_team = Team.create!(assignment: assignment)
        waitlisted_team2 = Team.create!(assignment: assignment)
        project_topic.signup_team(waitlisted_team)
        project_topic.signup_team(waitlisted_team2)
        expect {
          project_topic.drop_team(waitlisted_team)
        }.not_to change { project_topic.confirmed_teams.count }
        expect(project_topic.waitlisted_teams.first).to eq(waitlisted_team2)
      end
    end
  end

  describe '#available_slots' do
    it 'returns # of available slots correctly' do
      expect(project_topic.available_slots).to eq(2)
      project_topic.signup_team(team)
      expect(project_topic.available_slots).to eq(1)
    end
  end

  describe '#get_signed_up_teams' do
    it 'returns confirmed and waitlisted teams' do
      team2 = Team.create!(assignment: assignment)
      team3 = Team.create!(assignment: assignment)
      project_topic.signup_team(team)
      project_topic.signup_team(team2)
      project_topic.signup_team(team3)

      # Get SignedUpTeam records instead of Team objects
      topic_signups = project_topic.get_signed_up_teams
      expect(topic_signups.pluck(:team_id)).to include(team.id, team2.id, team3.id)
    end
  end

  describe '#slot_available?' do
    it 'returns true when slots available' do
      expect(project_topic.slot_available?).to be true
    end

    it 'returns false when slots full' do
      2.times { |n| project_topic.signup_team(Team.create!(assignment: assignment)) }
      expect(project_topic.slot_available?).to be false
    end
  end

  describe '#confirmed_teams' do
    it 'returns confirmed teams' do
      project_topic.signup_team(team)
      expect(project_topic.confirmed_teams).to include(team)
    end
  end

  describe '#waitlisted_teams' do
    it 'returns waitlisted teams in order' do
      teams = 5.times.map { Team.create!(assignment: assignment) }
      teams.each { |t| project_topic.signup_team(t) }

      # Get the first team from the relation
      expect(project_topic.waitlisted_teams.first).to eq(teams[2])
      expect(project_topic.waitlisted_teams.second).to eq(teams[3])
      expect(project_topic.waitlisted_teams.third).to eq(teams[4])
    end
  end
end