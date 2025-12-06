# frozen_string_literal: true

class AssignmentTeam < Team
  # Each AssignmentTeam must belong to a specific assignment
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'

  # Delegation to avoid Law of Demeter violations
  delegate :path, to: :assignment, prefix: true

  def hyperlinks
    submitted_hyperlinks.blank? ? [] : YAML.safe_load(submitted_hyperlinks)
  end

  def submit_hyperlink(hyperlink)
    hyperlink.strip!
    raise 'The hyperlink cannot be empty!' if hyperlink.empty?

    hyperlink = "https://#{hyperlink}" unless hyperlink.start_with?('http://', 'https://')
    # If not a valid URL, it will throw an exception
    response_code = Net::HTTP.get_response(URI(hyperlink))
    raise "HTTP status code: #{response_code}" if response_code.code =~ /[45][0-9]{2}/

    hyperlinks = self.hyperlinks
    hyperlinks << hyperlink
    self.submitted_hyperlinks = YAML.dump(hyperlinks)
    save
  end

  # Note: This method is not used yet. It is here in the case it will be needed.
  # @exception  If the index does not exist in the array

  def remove_hyperlink(hyperlink_to_delete)
    hyperlinks = self.hyperlinks
    hyperlinks.delete(hyperlink_to_delete)
    self.submitted_hyperlinks = YAML.dump(hyperlinks)
    save
  end

  # return the team given the participant
  def self.team(participant)
    return nil if participant.nil?

    team = nil
    teams_participants = TeamsParticipant.where(user_id: participant.user_id)
    return nil unless teams_participants

    teams_participants.each do |teams_participant|
      if teams_participant.team_id.nil?
        next
      end
      team = AssignmentTeam.find(teams_participant.team_id)
      return team if team.parent_id == participant.parent_id
    end
    nil
  end

  # Set the directory num for this team
  def set_team_directory_num
    return if directory_num && (directory_num >= 0)

    max_num = AssignmentTeam.where(parent_id:).order('directory_num desc').first.directory_num
    dir_num = max_num ? max_num + 1 : 0
    update(directory_num: dir_num)
  end

  # Gets the team directory path
  def path
    "#{assignment_path}/#{directory_num}"
  end

  # Copies the current assignment team to a course team
  # - Creates a new CourseTeam with a modified name
  # - Copies team members from the assignment team to the course team
  def copy_to_course_team(course)
    course_team = CourseTeam.new(
      name: "#{name} (Course)",              # Appends "(Course)" to the team name
      max_team_size: max_team_size,         # Preserves original max team size
      course: course                         # Associates new team with the given course
    )
    if course_team.save
      team_members.each do |member|
        course_team.add_member(member.user)  # Copies each member to the new course team
      end
    end
    course_team   # Returns the newly created course team object
  end

  protected

    # Validates if a user is eligible to join the team
  # - Checks whether the user is a participant of the associated assignment
  def validate_membership(user)
    # Ensure user is enrolled in the assignment by checking AssignmentParticipant
    assignment.participants.exists?(user: user)
  end

  private

  
  # Validates that the team is an AssignmentTeam or a subclass (e.g., MentoredTeam)
  def validate_assignment_team_type
    unless self.kind_of?(AssignmentTeam)
      errors.add(:type, 'must be an AssignmentTeam or its subclass')
    end
  end
end 
