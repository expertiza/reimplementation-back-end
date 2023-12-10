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
      user1 = create(:user, name: 'User 1')
      user2 = create(:user, name: 'User 2')
      team = create(:team)
      
      teams_user1 = create(:teams_user, user: user1, team: team)
      teams_user2 = create(:teams_user, user: user2, team: team)
  
      team_members = team.get_team_members
      expect(team_members).to include(user1, user2)
    end
  end  

  describe '.remove_team' do
    it 'removes the team user entry' do
      teams_user = create(:teams_user, user: user, team: team)
      TeamsUser.remove_team(user.id, team.id)
      expect(TeamsUser.where(user_id: user.id, team_id: team.id)).to be_empty
    end
  end
end
