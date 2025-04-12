class MentoredTeam < AssignmentTeam
  # E2516: Adds a member to the team and assigns a mentor if required.
  # Ensures that the mentor is only assigned once per assignment.
  # @param [User] user - The user to add
  # @param [Integer] _assignment_id - Assignment ID (optional)
  # @return [Boolean] true if member added successfully, false otherwise
  def add_member(user, _assignment_id = nil)
    # E2516: Raise error if the user is already part of the team
    raise "The user #{user.name} is already a member of the team #{name}" if user?(user)

    # E2516: Validate if the user can be added (team not full and mentor check passed)
    return false unless can_add_member?(user)

    # E2516: Add the user to the team and link them to the parent node
    add_team_user(user)
    add_participant_to_team(user)

    # E2516: Assign a mentor to the team only if necessary
    assign_mentor_if_needed(_assignment_id)

    # E2516: Log team member addition action
    ExpertizaLogger.info LoggerMessage.new('Model:Team', user.name, "Added member to the team #{id}")
    true
  end

  # E2516: Imports multiple team members from a CSV row
  # @param [Hash] row_hash - Hash with team members' data
  def import_team_members(row_hash)
    row_hash[:teammembers].each do |teammate|
      # E2516: Skip empty or invalid entries
      next if teammate.to_s.strip.empty?

      # E2516: Find the user or raise error if user not found
      user = find_or_raise_user(teammate)

      # E2516: Add the user if they are not already in the team
      add_member(user, parent_id) if user_not_in_team?(user)
    end
  end

  private

  # E2516: Validates if a user can be added to the team
  # @param [User] user - The user to check
  # @return [Boolean] true if user can be added, false otherwise
  def can_add_member?(user)
    # E2516: Check if the team is not full and mentor conditions are satisfied
    !full? && mentor_assignment_valid?(user)
  end

  # E2516: Creates a TeamsUser and links it to the parent TeamNode
  # @param [User] user - The user to add
  def add_team_user(user)
    t_user = TeamsUser.create!(user_id: user.id, team_id: id)
    parent = TeamNode.find_by(node_object_id: id)

    # E2516: Create a TeamUserNode to link user to the team node
    TeamUserNode.create!(parent_id: parent.id, node_object_id: t_user.id)
  end

  # E2516: Adds the participant to the team
  # @param [User] user - The user to be added as a participant
  def add_participant_to_team(user)
    parent = TeamNode.find_by(node_object_id: id)
    # E2516: Add the participant to the team
    add_participant(parent.id, user)
  end

  # E2516: Assigns a mentor to the team only if required
  # @param [Integer] _assignment_id - Assignment ID (optional)
  def assign_mentor_if_needed(_assignment_id)
    # E2516: Assign mentor only if mentor conditions are satisfied
    MentorManagement.assign_mentor(_assignment_id, id) if mentor_assignment_valid?
  end

  # E2516: Checks if assigning a mentor is valid for the team
  # @param [User] user - The user being added
  # @return [Boolean] true if mentor can be assigned, false otherwise
  def mentor_assignment_valid?(user)
    # E2516: Allow adding if the user is a mentor or no mentor exists in the team
    return true if mentor_user?(user) || !team_has_mentor?

    # E2516: Raise error if team already has a mentor
    raise "A mentor is already assigned to the team #{id}"
  end

  # E2516: Checks if the user is not already part of the team
  # @param [User] user - The user to check
  # @return [Boolean] true if user is not in the team, false otherwise
  def user_not_in_team?(user)
    TeamsUser.find_by(team_id: id, user_id: user.id).nil?
  end

  # E2516: Finds a user or raises an error if the user is not found
  # @param [String] teammate - Name of the user to be searched
  # @return [User] the user object if found
  def find_or_raise_user(teammate)
    user = User.find_by(name: teammate.to_s)

    # E2516: Raise ImportError if user not found
    raise ImportError, "The user '#{teammate}' was not found. <a href='/users/new'>Create</a> this user?" if user.nil?

    user
  end
end
