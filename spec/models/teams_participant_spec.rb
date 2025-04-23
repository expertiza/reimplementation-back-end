require 'rails_helper'

RSpec.describe TeamsParticipant, type: :model do
  let(:participant) { create(:participant) }
  let(:team) { create(:assignment_team) }
  let!(:teams_participant) { create(:teams_participant, participant: participant, team: team) }

  describe '.team_members' do
    it 'returns all team members' do
      members = TeamsParticipant.team_members(team.id)
      expect(members).to include(participant.user)
    end
  end

  describe '.remove_participant_from_team' do
    it 'removes a participant from the team' do
      expect { TeamsParticipant.remove_participant_from_team(participant.id, team.id) }.to change { TeamsParticipant.count }.by(-1)
    end
  end
end
