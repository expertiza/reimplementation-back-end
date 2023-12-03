# spec/models/teams_user_spec.rb
require 'rails_helper'

RSpec.describe TeamsUser, type: :model do
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  describe '#name' do
    it 'returns the user name' do
      teams_user = create(:teams_user, user: user, team: team)
      expect(teams_user.name).to eq(user.name)
    end
  end

  describe '#get_team_members' do
    it 'returns team members' do
      # Implement this test as per your specific requirements
    end
  end

  describe '.remove_team' do
    it 'removes the team user entry' do
      teams_user = create(:teams_user, user: user, team: team)
      TeamsUser.remove_team(user.id, team.id)
      expect(TeamsUser.where(user_id: user.id, team_id: team.id)).to be_empty
    end
  end

  describe '.first_by_team_id' do
    it 'returns the first team user by team id' do
      teams_user = create(:teams_user, team: team)
      expect(TeamsUser.first_by_team_id(team.id)).to eq(teams_user)
    end
  end

  describe '.team_empty?' do
    it 'returns true if the team is empty' do
      team = create(:team)
      expect(TeamsUser.team_empty?(team.id)).to be true
    end

    it 'returns false if the team is not empty' do
      teams_user = create(:teams_user, team: team)
      expect(TeamsUser.team_empty?(team.id)).to be false
    end
  end
end
