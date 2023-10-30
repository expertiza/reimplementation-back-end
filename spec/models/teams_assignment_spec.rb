require 'rails_helper'

RSpec.describe TeamsAssignment, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"

  let(:team_assignment) { create(:teams_assignment) } # You may need to adjust this based on your factories
  
  describe '.import_teams_from_csv' do
    it 'imports teams from a CSV file' do
      file = fixture_file_upload('teams.csv', 'text/csv') # Upload a sample CSV file

      expect {
        TeamsAssignment.import_teams_from_csv(file)
      }.to change(TeamsAssignment, :count).by(1)

      # Add further expectations to ensure the data was imported correctly
      expect(TeamsAssignment.last.name).to eq('Team 1')
      expect(TeamsAssignment.last.users.count).to eq(2)
    end
  end

  describe '.export_teams_to_csv' do
    it 'exports teams to a CSV file' do
      # Create some teams and users (you may use factories or create them here)
      team1 = create(:teams_assignment, name: 'Team 1')
      team2 = create(:teams_assignment, name: 'Team 2')
      user1 = create(:user, name: 'User 1')
      user2 = create(:user, name: 'User 2')

      # Assign users to teams (you may need to adjust the associations)
      team1.users << user1
      team2.users << user2

      csv_data = nil

      expect {
        Tempfile.create(['exported_teams', '.csv']) do |file|
          csv_data = file
          TeamsAssignment.export_teams_to_csv(csv_data.path)
        end
      }.to change { File.exist?(csv_data.path) }.from(false).to(true)

      # Now you can read the CSV file (e.g., using CSV library) and check its contents
      # Assert that the contents match the expected data
    end
  end

  describe '.create_team' do
    it 'creates a new team and associated team node' do
      name = 'Sample Team'

      expect {
        team = TeamsAssignment.create_team(name)
      }.to change(Team, :count).by(1)

      last_team = Team.last
      expect(last_team.name).to eq(name)
      expect(last_team.parent_id).to eq(team_assignment.id)

      # Ensure an associated team node was created
      expect(TeamNode.find_by(node_object_id: last_team.id)).not_to be_nil
    end
  end

  describe '.add_user_to_team' do
    it 'adds a user to a team' do
      team = create(:teams_assignment)
      user = create(:user)

      expect {
        TeamsAssignment.add_user_to_team(team, user)
      }.to change(TeamsUser, :count).by(1)

      team.reload
      expect(team.users).to include(user)
    end

    it 'does not add the user if they are already a member of the team' do
      team = create(:teams_assignment)
      user = create(:user)
      team.users << user

      expect {
        TeamsAssignment.add_user_to_team(team, user)
      }.not_to change(TeamsUser, :count)
    end
  end

  describe '.remove_user_from_team' do
    it 'removes a user from a team' do
      team = create(:teams_assignment)
      user = create(:user)
      team.users << user

      expect {
        TeamsAssignment.remove_user_from_team(team, user)
      }.to change(TeamsUser, :count).by(-1)

      team.reload
      expect(team.users).not_to include(user)
    end

    it 'does nothing if the user is not a member of the team' do
      team = create(:teams_assignment)
      user = create(:user)
      other_user = create(:user)
      team.users << user

      expect {
        TeamsAssignment.remove_user_from_team(team, other_user)
      }.not_to change(TeamsUser, :count)
    end
  end

  describe '.generate_team_name' do
    context 'when there are no existing teams' do
      it 'generates a unique team name' do
        generated_name = TeamsAssignment.generate_team_name
        expect(generated_name).to start_with('Team_')
      end
    end

    context 'when there are existing teams' do
      it 'generates a unique team name with a prefix' do
        # Create an existing team with the generated name
        existing_name = TeamsAssignment.generate_team_name
        create(:teams_assignment, name: existing_name)

        # Generate a new team name with the same prefix
        generated_name = TeamsAssignment.generate_team_name

        expect(generated_name).to start_with(existing_name.split.first) # Check the prefix
        expect(generated_name).to match(/\A#{existing_name.split.first} Team_\d+\z/) # Check the format
      end
    end
  end
  
end
