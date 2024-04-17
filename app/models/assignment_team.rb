class AssignmentTeam < Team
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'assignment_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'

  def hyperlinks
    submitted_hyperlinks.blank? ? [] : YAML.safe_load(submitted_hyperlinks)
  end

  def submit_hyperlink(hyperlink)
    hyperlink.strip!
    raise 'The hyperlink cannot be empty!' if hyperlink.empty?

    hyperlink = "https://#{hyperlink}" unless hyperlink.start_with?('http://', 'https://')
    # If not a valid URL, it will throw an exception
    response_code = Net::HTTP.get_response(URI(hyperlink))
    raise "HTTP status code: #{response_code}" if response_code =~ /[45][0-9]{2}/

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
    teams_users = TeamsUser.where(users_id: participant.user_id)
    return nil unless teams_users

    teams_users.each do |teams_user|
      if teams_user.teams_id.nil?
        next
      end
      team = Team.find(teams_user.teams_id)
      return team if team.assignment_id == participant.assignment_id
    end
    nil
  end

  # Set the directory num for this team
  def set_student_directory_num
    return if directory_num && (directory_num >= 0)

    max_num = AssignmentTeam.where(assignment_id:).order('directory_num desc').first.directory_num
    dir_num = max_num ? max_num + 1 : 0
    update(directory_num: dir_num)
  end

  # Gets the student directory path
  def path
    "#{assignment.path}/#{team.directory_num}"
  end
end
