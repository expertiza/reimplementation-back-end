class TeamsAssignment < ApplicationRecord
  require 'csv'  # Require the 'csv' library
  
  has_many :users, through: :teams_users
  has_many :join_team_requests, dependent: :destroy
  has_one :team_node, foreign_key: :node_object_id, dependent: :destroy
  has_many :signed_up_teams, dependent: :destroy
  has_many :bids, dependent: :destroy
  has_paper_trail

  # Import teams from a CSV file
  def self.import_teams_from_csv(file)
    CSV.foreach(file.path, headers: true) do |row|
      team = self.find_or_create_by(name: row['name'])
      team.users << User.find_by(name: row['user_name'])
    end
  end

  def self.export_teams_to_csv(file)
    CSV.open(file.path, 'w') do |csv|
    csv << ['name', 'user_name'] # Add relevant column names

      all.each do |team|
        team.users.each do |user|
          csv << [team.name, user.name]
        end
      end
    end
  end

  # Method to create a new team
  def create_team(name)
    team = Team.create(name: name, parent_id: self.id)
    TeamNode.create(parent_id: self.id, node_object_id: team.id)
    team
  end

  # Method to add a user to a team
  def add_user_to_team(team, user)
    # Check if the user is already a member of the team
    return if team.users.include?(user)

    TeamsUser.create(team_id: team.id, user_id: user.id)
    # Optionally, you can add this user to any related associations, like CourseParticipants or AssignmentParticipants
  end

  # Method to remove a user from a team
  def remove_user_from_team(team, user)
    team_user = TeamsUser.find_by(team_id: team.id, user_id: user.id)
    team_user&.destroy
  end

  # Generate the team name
  def self.generate_team_name(team_name_prefix = '')
    counter = 1
    loop do
      team_name = "#{team_name_prefix} Team_#{counter}"
      return team_name unless TeamsAssignment.find_by(name: team_name)

      counter += 1
    end
  end
  
end

