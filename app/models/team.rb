class Team < ApplicationRecord
  has_many :signed_up_teams, dependent: :destroy
  has_many :teams_participants, dependent: :destroy
  has_many :join_team_requests, dependent: :destroy
  has_one :team_node, foreign_key: :node_object_id, dependent: :destroy
  has_many :users, through: :teams_participants
  has_many :bids, dependent: :destroy
  has_many :participants
  belongs_to :assignment
  attr_accessor :max_participants
  scope :find_team_for_assignment_and_user, lambda { |assignment_id, user_id|
    joins(:teams_participants).where('teams.parent_id = ? AND teams_participants.user_id = ?', assignment_id, user_id)
  }
  # TODO Team implementing Teams controller and model should implement this method better.
  # TODO partial implementation here just for the functionality needed for join_team_tequests controller
  def full?
    max_participants ||= 3
    if participants.count >= max_participants
      true
    else
      false
    end
  end

  # Adds a user to the team while handling potential errors such as duplicate membership.
# This is a wrapper around the `add_member` method with error handling.
# Params:
# - user: The user to be added to the team.
# - parent_id: The ID of the parent entity (assignment or course).
# Returns:
# - true if the user was successfully added.
# - A hash with an error message if the addition fails.
def add_participants_with_handling(user, parent_id)
  begin
    # Attempt to add the user to the team.
    addition_result = add_member(user, parent_id)
    addition_result
  rescue StandardError => e
    # Return a failure message if an error occurs (e.g., user already in the team).
    { success: false, error: "The user #{user.name} is already a member of the team #{name}" }
  end
end

# Adds a user to the team if they are not already a member and the team is not full.
# Also creates the necessary team user and team node entries.
# Params:
# - user: The user to be added.
# - _assignment_id (optional): The ID of the assignment (not used directly in this implementation).
# Returns:
# - true if the user was successfully added to the team.
# - false if the team is full or if the user cannot be added.
def add_participant(user, _assignment_id = nil)
  # Raise an error if the user is already a member of the team.
  raise "The user #{user.name} is already a member of the team #{name}" if member?(user)

  # Check if the team is not full before adding the user.
  if !full?
    # Create a relationship between the user and the team.
    team_user_relationship = TeamsParticipant.create(user_id: user.id, team_id: id)

    # Create the corresponding team user node in the hierarchy.
    team_node = TeamNode.find_by(node_object_id: id)
    TeamUserNode.create(parent_id: team_node.id, node_object_id: team_user_relationship.id)

    # Add the user as a participant for the parent assignment or course.
    add_participant_to_parent_entity(parent_id, user)

    # Log the successful addition of the user to the team.
    ExpertizaLogger.info LoggerMessage.new('Model:Team', user.name, "Added member to the team #{id}")
    true
  else
    false
  end
end

# Checks if the given user is already a member of the team.
# Params:
# - user: The user to check for membership.
# Returns:
# - true if the user is already a member of the team.
# - false otherwise.
def participant_present?(user)
  users.include?(user)
end

# Retrieves all participants associated with the team.
# Participants are derived from the users belonging to the team.
# Returns:
# - An array of participant objects.
def participants
  users.where(parent_id: parent_id || current_user_id).flat_map(&:participants)
end
alias get_participants participants

# Retrieves the full names of all users in the team.
# Returns:
# - An array of strings representing the full names of the team members.
def participant_full_names
  users.map(&:fullname)
end
alias author_names participant_full_names

# Determines the current size of the team, excluding mentors.
# Params:
# - team_id: The ID of the team whose size is being checked.
# Returns:
# - The number of non-mentor members in the team.
def self.size(team_id)
  count = 0
  team_participants = TeamsParticipant.where(team_id: team_id)

  # Exclude mentors from the count.
  team_participants.each do |team_participants|
    team_participants_name = team_participants.name
    count += 1 unless team_participants_name.include?(' (Mentor)')
  end
  count
end

# Checks if a team with the given name already exists for a parent entity (assignment or course).
# Raises an error if a team with the same name already exists.
# Params:
# - parent: The parent entity (assignment or course) associated with the team.
# - name: The name of the team to check for uniqueness.
# - team_type: The type of team (e.g., 'Assignment', 'Course').
def self.check_for_existing(parent, name, team_type)
  existing_teams = Object.const_get("#{team_type}Team").where(parent_id: parent.id, name: name)

  # Raise an error if any team with the same name is found.
  unless existing_teams.empty?
    raise TeamExistsError, "The team name #{name} is already in use."
  end
end

# Retrieves all teams that a specific user belongs to for a given assignment.
# Params:
# - assignment_id: The ID of the assignment.
# - user_id: The ID of the user.
# Returns:
# - A list of team IDs for the user within the specified assignment.
def self.find_team_participants(assignment_id, user_id)
  TeamsParticipant.joins('INNER JOIN teams ON teams_participants.team_id = teams.id')
           .select('teams.id as team_id')
           .where('teams.parent_id = ? AND teams_participants.user_id = ?', assignment_id, user_id)
end

end