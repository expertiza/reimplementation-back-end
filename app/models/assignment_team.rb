class AssignmentTeam < Team
  attr_accessor :current_user
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :review_response_maps, foreign_key: 'reviewee_id'
  has_many :responses, through: :review_response_maps, foreign_key: 'map_id'

  # Returns the ID of the current user if they are a participant in the team
  def current_user_id
    return @current_user.id if @current_user && participants.map(&:user).include?(@current_user)

    nil
  end

  # Returns the user ID of the first participant in the team
  def first_user_id
    participants.first&.user_id
  end

  # Returns the type of review map used for this team (default: 'ReviewResponseMap')
  def review_map_type
    'ReviewResponseMap'
  end

  # Assigns a reviewer to this team by creating a ReviewResponseMap
  # - Reviewer is linked with the assignment and this team
  def assign_reviewer(reviewer)
    assignment = Assignment.find(parent_id)
    raise 'The assignment cannot be found.' if assignment.nil?

    ReviewResponseMap.create(reviewee_id: id, reviewer_id: reviewer.reviewer.id, reviewed_object_id: assignment.id, team_reviewing_enabled: assignment.team_reviewing_enabled)
  end

  # Returns the team itself as its own reviewer
  def reviewer
    self
  end

  # Returns true if the given reviewer has already reviewed this team
  def reviewed_by?(reviewer)
    ReviewResponseMap.where('reviewee_id = ? && reviewer_id = ? && reviewed_object_id = ?', id, reviewer.reviewer.id, assignment.id).count > 0
  end

  # Returns the topic ID that this team is signed up for (if any and not waitlisted)
  def topic_id
    SignedUpTeam.find_by(team_id: id, is_waitlisted: 0)&.sign_up_topic_id
  end

  # Returns true if the team has submitted either files or hyperlinks
  def has_submissions?
    submitted_files.any? || submitted_hyperlinks.present?
  end

  # Returns participants for this team who are part of the same assignment
  def participants
    TeamsParticipant.where(team_id: id).includes(:participant).map(&:participant).select { |p| p.assignment_id == assignment_id }
  end
  alias get_participants participants

  # Deletes the team and any associated signup records if it's an AssignmentTeam
  def delete
    if self[:type] == 'AssignmentTeam'
      sign_up = SignedUpTeam.find_team_participants(parent_id.to_s).select { |p| p.team_id == id }
      sign_up.each(&:destroy)
    end
    super
  end

  # Destroys the team and all related review response maps
  def destroy
    review_response_maps.each(&:destroy)
    super
  end

  # Retrieves submitted file paths for the team directory, if present
  def submitted_files(path = self.path)
    files = []
    files = files(path) if directory_num
    files
  end

  # Imports a team from CSV into the given assignment
  # - Delegates logic to base Team class
  def self.import(row, assignment_id, options)
    raise ImportError, "The assignment with the id \"#{assignment_id}\" was not found. <a href='/assignment/new'>Create</a> this assignment?" unless Assignment.find_by(id: assignment_id)
    Team.import(row, assignment_id, options, AssignmentTeam)
  end

  # Exports all assignment teams for a given parent ID into CSV format
  def self.export(csv, parent_id, options)
    Team.export(csv, parent_id, options, AssignmentTeam)
  end

  # Copies team members from this team to another team
  # - Converts participants if copying to a different team type
  def copy(new_team)
    members = TeamsParticipant.where(team_id: id)
    members.each do |member|
      old_participant = member.participant

      new_participant =
        if new_team.is_a?(AssignmentTeam)
          AssignmentParticipant.find_or_create_by!(
            user_id: old_participant.user_id,
            assignment_id: new_team.assignment_id
          ) do |p|
            p.handle = old_participant.handle
          end
        else
          nil
        end

      TeamsParticipant.create!(
        team_id: new_team.id,
        participant: new_participant || member.participant
      )

      parent = Assignment.find_by(id: parent_id) || Course.find_by(id: new_team.parent_id)
      TeamUserNode.create!(parent_id: parent.id, node_object_id: new_team.id)
    end
  end

  # Copies the current assignment team to a CourseTeam
  def copy_assignment_to_course(course_id)
    new_team = CourseTeam.create_team_and_node(course_id)
    new_team.name = name
    new_team.save
    copy(new_team)
  end

  # Factory Method that returns the participant model class for assignment-based teams
  # - Used to dynamically select correct participant type
  def participant_class
    AssignmentParticipant
  end

  # Loads submitted hyperlinks for the team from YAML format
  def hyperlinks
    submitted_hyperlinks.blank? ? [] : YAML.safe_load(submitted_hyperlinks)
  end

  # Submits a new hyperlink for the team, validates it, and saves the updated list
  def submit_hyperlink(hyperlink)
    hyperlink.strip!
    raise 'The hyperlink cannot be empty!' if hyperlink.empty?
    hyperlink = 'http://' + hyperlink unless hyperlink.start_with?('http://', 'https://')
    response_code = Net::HTTP.get_response(URI(hyperlink))
    raise "HTTP status code: #{response_code}" if response_code =~ /[45][0-9]{2}/

    hyperlinks = self.hyperlinks
    hyperlinks << hyperlink
    self.submitted_hyperlinks = YAML.dump(hyperlinks)
    save
  end

  # Removes a previously submitted hyperlink from the list and saves
  def remove_hyperlink(hyperlink_to_delete)
    hyperlinks = self.hyperlinks
    hyperlinks.delete(hyperlink_to_delete)
    self.submitted_hyperlinks = YAML.dump(hyperlinks)
    save
  end

  # Recursively fetches all file paths within a given directory
  def files(directory)
    return [] unless File.directory?(directory)

    (Dir.entries(directory) - ['.', '..']).flat_map do |entry|
      path = File.join(directory, entry)
      File.directory?(path) ? files(path) : [path]
    end
  end

  # Finds the team associated with a given participant
  # - Only returns the team if it belongs to the same assignment
  def self.team(participant)
    return nil if participant.nil?

    teams_participants = TeamsParticipant.where(participant_id: participant.id)
    return nil if teams_participants.empty?

    teams_participants.each do |teams_participant|
      next if teams_participant.team_id.nil?
      team = Team.find_by(id: teams_participant.team_id)
      return team if team&.parent_id == participant.assignment_id
    end

    nil
  end

  # Returns the CSV header fields for exporting assignment teams
  def self.export_fields(options)
    fields = ['Team Name']
    fields << 'Team members' if options[:team_name] == 'false'
    fields << 'Assignment Name'
    fields
  end

  # Removes and destroys the team with the given ID
  def self.remove_team_by_id(id)
    old_team = AssignmentTeam.find(id)
    old_team.destroy unless old_team.nil?
  end

  # Returns the full directory path for the team’s files, based on assignment and team directory number
  def path
    File.join(assignment.directory_path, directory_num.to_s)
  end

  # Sets the team’s directory number to the next available value
  def set_team_directory_num
    return if directory_num && (directory_num >= 0)
    max_num = AssignmentTeam.where(parent_id: parent_id).order('directory_num desc').first&.directory_num
    dir_num = max_num ? max_num + 1 : 0
    update(directory_num: dir_num)
  end

  # Returns true if the team has been reviewed by any response map
  def has_been_reviewed?
    ResponseMap.where(reviewee_id: id, reviewed_object_id: parent_id).any?
  end

  # Returns the most recent submission record for this team in the assignment
  def most_recent_submission
    assignment = Assignment.find(parent_id)
    SubmissionRecord.where(team_id: id, assignment_id: assignment.id).order(updated_at: :desc).first
  end

  # Returns the participant ID of the reviewer if the given user is part of this team
  def get_logged_in_reviewer_id(current_user_id)
    participants.each do |participant|
      return participant.id if participant.user.id == current_user_id
    end
    nil
  end

  # Returns true if the given user is a reviewer in the current team
  def current_user_is_reviewer?(current_user_id)
    get_logged_in_reviewer_id(current_user_id) != nil
  end

  # Assigns the team to a specific signup topic and updates node associations
  def assign_team_to_topic(signup_topic)
    SignedUpTeam.create(sign_up_topic_id: signup_topic.id, team_id: id, is_waitlisted: 0)
    team_node = TeamNode.create(parent_id: signup_topic.assignment_id, node_object_id: id)

    TeamsParticipant.where(team_id: id).each do |teams_participant|
      TeamUserNode.create(parent_id: team_node.id, node_object_id: teams_participant.id)
    end
  end
end
