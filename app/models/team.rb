class Team < ApplicationRecord
  validates :name, uniqueness: { scope: :parent_id, message: "is already in use." }

  has_many :teams_participants, dependent: :destroy
  has_many :join_team_requests, dependent: :destroy
  has_one :team_node, foreign_key: :node_object_id, dependent: :destroy
  has_many :signed_up_teams, dependent: :destroy
  has_many :bids, dependent: :destroy
  has_many :participants, through: :teams_participants
  belongs_to :assignment, optional: true
  belongs_to :course,     optional: true

  has_paper_trail

  validate :assignment_or_course_presence

  scope :find_team_for_assignment_and_user, lambda { |assignment_id, user_id|
    joins(teams_participants: :participant)
      .where('teams.parent_id = ? AND participants.assignment_id = ? AND participants.user_id = ?', assignment_id, assignment_id, user_id)
  }

  # Get the parent entity type as a string (ex: "Course" for CourseTeam)
  def parent_entity_type
    self.class.name.gsub('Team', '')
  end

  # Fetch the parent entity instance by ID (ex: Course.find(id) for CourseTeam)
  def self.find_parent_entity(id)
    Object.const_get(self.name.gsub('Team', '')).find(id)
  end

  # Returns all participants associated with the team
  def participants
    teams_participants.includes(:participant).map(&:participant)
  end
  alias get_participants participants

  # Copies content from each object in `source` to the `destination` object
  def self.copy_content(source, destination)
    source.each do |each_element|
      each_element.copy(destination.id)
    end
  end

  # Deletes the team and its associated team participants and team node
  def delete
    TeamsParticipant.where(team_id: id).find_each(&:destroy)
    node = TeamNode.find_by(node_object_id: id)
    node.destroy if node
    destroy
  end

  # Returns the node type associated with the team (used in tree structure)
  def node_type
    'TeamNode'
  end

  # Returns the full names of all users in the team
  def member_names
    participants.map { |participant| participant.user.fullname }
  end

  # Returns true if the given user is a member of the team; otherwise false
  def has_as_member?(user)
    participants.any? { |p| p.user_id == user.id }
  end

  # Returns true if the team has reached the maximum allowed team size; otherwise false
  def full?
    return false if parent_id.nil?

    max_team_members = Assignment.find(parent_id).max_team_size
    curr_team_size = size
    curr_team_size >= max_team_members
  end

  # Adds a user to the team after ensuring they are not already in it and the team is not full
  def add_member(user)
    raise "The user #{user.name} is already a member of the team #{name}" if has_as_member?(user)
    return false if full?

    participant = participant_class.find_by(user_id: user.id, assignment_id: parent_id) ||
      participant_class.find_by(user_id: user.id, course_id: parent_id)

    raise "Participant not found for user #{user.id} in assignment #{parent_id}" unless participant

    if TeamsParticipant.exists?(participant_id: participant.id, team_id: id)
      raise "The user #{user.name} is already a member of the team #{name}"
    end

    t_participant = TeamsParticipant.create!(participant: participant, team_id: id)
    parent_node = TeamNode.find_by(node_object_id: id)
    TeamUserNode.create!(parent_id: parent_node.id, node_object_id: t_participant.id)

    unless CourseParticipant.find_by(assignment_id: parent_id, user_id: user.id)
      CourseParticipant.create(assignment_id: parent_id, user_id: user.id, permission_granted: user.master_permission_granted)
    end

    true
  end

  # Creates and returns a new participant for the team if one does not already exist
  def add_participant(user)
    foreign_key = participant_class == AssignmentParticipant ? :assignment_id : :parent_id

    existing = participant_class.find_by(foreign_key => parent_id, user_id: user.id)
    return nil if existing

    participant_class.create(
      foreign_key => parent_id,
      user_id: user.id,
      permission_granted: user.master_permission_granted,
      handle: "handle_#{user.id}"
    )
  end

  # Returns the number of participants in the team
  def size
    participants.size
  end

  # Creates random teams from unassigned users and fills underpopulated teams
  # - Ensures all teams have at least `min_team_size` members
  # - Creates new teams if users remain unassigned
  def self.create_random_teams(parent, team_type, min_team_size)
    participant_model = "#{parent.class}Participant".constantize
    participants = participant_model.where(assignment_id: parent.id, can_mentor: [false, nil])
    participants = participants.sort { rand(-1..1) }
    users = participants.map { |p| User.find(p.user_id) }.to_a
    teams = Team.where(parent_id: parent.id, type: parent.class.to_s + 'Team').to_a
    teams.each do |team|
      TeamsParticipant.where(team_id: team.id).each do |teams_participant|
        users.delete(User.find(teams_participant.user_id))
      end
    end
    teams.reject! { |team| team.size >= min_team_size }
    teams.sort_by { |team| team.size }.reverse!
    teams.each do |team|
      member_num_difference = min_team_size - team.size
      while member_num_difference > 0 && !users.empty?
        team.add_member(users.first)
        users.shift
        member_num_difference -= 1
      end
      break if users.empty?
    end
    team_from_users(min_team_size, parent, team_type, users) unless users.empty?
  end

  # Creates a specified number of new teams and assigns users in chunks of `min_team_size`
  # - Used by `create_random_teams` to handle leftover users
  def self.team_from_users(min_team_size, parent, team_type, users)
    num_of_teams = users.length.fdiv(min_team_size).ceil
    next_team_member_index = 0
    (1..num_of_teams).to_a.each do |i|
      team = Object.const_get(team_type + 'Team').create(name: 'Team_' + i.to_s, parent_id: parent.id, assignment_id: parent.id)
      TeamNode.create(parent_id: parent.id, node_object_id: team.id)
      min_team_size.times do
        break if next_team_member_index >= users.length

        user = users[next_team_member_index]
        team.add_member(user)
        next_team_member_index += 1
      end
    end
  end

  # Generates a new team name with an incremented suffix (e.g., "Team_1", "Team_2", etc.)
  # - Ensures no name collisions for the given prefix
  def self.generate_team_name(prefix = '')
    prefix = 'Team' if prefix.blank?
    last_team = Team.where('name LIKE ?', "#{prefix}_%")
                    .order(Arel.sql("CAST(SUBSTRING(name, LENGTH('#{prefix}_') + 1) AS UNSIGNED) DESC"))
                    .first
    counter = last_team ? last_team.name.scan(/\d+/).first.to_i + 1 : 1
    "#{prefix}_#{counter}"
  end

  # Returns the team's name
  # - Returns an anonymized version if the user is in anonymized view mode
  def name(ip_address = nil)
    if User.anonymized_view?(ip_address)
      return "Anonymized_Team_\#{self[:id]}"
    else
      return self[:name]
    end
  end

  # Imports and adds users to the team based on a hash of team members
  # - Raises an error if any user in the list is not found
  def import_team_members(row_hash)
    row_hash[:teammembers].each_with_index do |teammate, _index|
      user = User.find_by(name: teammate.to_s)
      if user.nil?
        raise ImportError, "The user '\#{teammate}' was not found. <a href='/users/new'>Create</a> this user?"
      else
        add_member(user)
      end
    end
  end

  # Imports a team from a row of CSV data
  # - Handles duplicate team names based on `options[:handle_dups]`
  # - Creates new teams if needed and adds members
  def self.import(row_hash, id, options, teamtype)
    raise ArgumentError, 'Not enough fields on this line.' if row_hash.empty? || (row_hash[:teammembers].empty? && (options[:has_teamname] == 'true_first' || options[:has_teamname] == 'true_last'))
    if options[:has_teamname] == 'true_first' || options[:has_teamname] == 'true_last'
      name = row_hash[:teamname].to_s
      team = where(['name =? && parent_id =?', name, id]).first
      team_exists = !team.nil?
      name = handle_duplicate(team, name, id, options[:handle_dups], teamtype)
    else
      if teamtype == CourseTeam
        name = generate_team_name(Course.find(id).name)
      elsif teamtype == AssignmentTeam || teamtype == MentoredTeam
        name = generate_team_name(Assignment.find(id).name)
      end
    end
    if name
      team = teamtype.create_team_and_node(id)
      team.name = name
      team.save
    end
    team.import_team_members(row_hash) unless team_exists && options[:handle_dups] == 'ignore'
  end

  # Handles team name conflicts during import
  # - Based on the duplication strategy (ignore, rename, replace), takes appropriate action
  # - Returns a valid name to use or nil if ignored
  def self.handle_duplicate(team, name, id, handle_dups, teamtype)
    return name if team.nil?
    return nil if handle_dups == 'ignore'

    if handle_dups == 'rename'
      if teamtype == CourseTeam
        return generate_team_name(Course.find(id).name)
      elsif  teamtype == AssignmentTeam
        return generate_team_name(Assignment.find(id).name)
      end
    end
    if handle_dups == 'replace'
      team.delete
      return name
    else
      return nil
    end
  end

  # Exports all teams and their members for a given parent (assignment/course)
  # - Team names and member names are output to CSV format
  def self.export(csv, parent_id, options, teamtype)
    teams = teamtype.where(parent_id: parent_id)
    teams.each do |team|
      output = []
      output.push(team.name)
      if options[:team_name] == 'false'
        team_members = TeamsParticipant.where(team_id: team.id)
        team_members.each do |tp|
          output.push(tp.participant.user.name)
        end
      end
      csv << output
    end
    csv
  end

  # Creates a new team and its corresponding TeamNode
  # - Optionally adds a list of users to the newly created team
  # - Removes any previous team associations for these users under the same parent
  def self.create_team_and_node(parent_id, user_ids = [])
    parent = find_parent_entity parent_id
    team_name = Team.generate_team_name(parent.name)
    team = create(name: team_name, parent_id: parent_id)
    TeamNode.create(parent_id: parent_id, node_object_id: team.id)

    user_ids.each do |user_id|
      participant = Participant.find_by(user_id: user_id, assignment_id: parent_id)
      if participant
        team_participant = TeamsParticipant.where(participant_id: participant.id)
                                    .find { |tp| tp.team.parent_id == parent_id }
        team_participant&.destroy
        team.add_member(User.find(user_id))
      end
    end unless user_ids.empty?

    team
  end

  # Finds the team a user is part of for a given assignment
  # - Returns a relation selecting only the team ID
  def self.find_team_for_user(assignment_id, user_id)
    TeamsParticipant
      .joins(:team, :participant)
      .where(teams: { parent_id: assignment_id }, participants: { assignment_id: assignment_id, user_id: user_id })
      .select('teams.id as t_id')
  end

  # Returns true if the given participant is part of the team; otherwise false
  def has_participant?(participant)
    participants.include?(participant)
  end

  private

  # Validates that the team belongs to either an assignment or a course
  # - Raises errors if neither or both are set to ensure proper team context
  def assignment_or_course_presence
    has_assignment = assignment_id.present? || parent_id.present?
    has_course     = course_id.present?

    unless has_assignment || has_course
      errors.add(:base, "Team must belong to either an assignment or a course")
    end

    if has_assignment && has_course
      errors.add(:base, "Team cannot be both AssignmentTeam and a CourseTeam")
    end
  end

  # Checks if a participant is eligible to join the team
  # - Ensures team is not full and participant belongs to the same assignment or course
  def can_participant_join_team?(participant)
    return false if full?

    if assignment_id.present?
      participant.assignment_id == assignment_id &&
        !TeamsParticipant.exists?(participant_id: participant.id)
    else
      participant.course_id == course_id &&
        !TeamsParticipant.exists?(participant_id: participant.id)
    end
  end
end
