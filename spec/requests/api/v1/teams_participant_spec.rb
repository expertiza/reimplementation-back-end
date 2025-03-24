require 'rails_helper'

RSpec.describe TeamsParticipant, type: :model do
  let(:assignment) { create(:assignment) }
  let(:team) { create(:assignment_team, assignment: assignment) }
  let(:user) { create(:user) }
  let(:participant) { create(:participant, user: user, assignment: assignment) }
  let(:teams_participant) { create(:teams_participant, team: team, participant: participant) }

  describe 'associations' do
    it { should belong_to(:team) }
    it { should belong_to(:participant) }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(teams_participant).to be_valid
    end

    it 'is invalid without a team' do
      teams_participant.team = nil
      expect(teams_participant).not_to be_valid
    end

    it 'is invalid without a participant' do
      teams_participant.participant = nil
      expect(teams_participant).not_to be_valid
    end
  end

  describe '#team_members' do
    it 'returns team members for a given team' do
      teams_participant
      expect(TeamsParticipant.team_members(team.id)).to include(participant)
    end
  end

  describe '#participant?' do
    it 'returns true if user is a participant' do
      expect(teams_participant.participant?(user)).to be true
    end

    it 'returns false if user is not a participant' do
      another_user = create(:user)
      expect(teams_participant.participant?(another_user)).to be false
    end
  end
end
