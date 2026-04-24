# frozen_string_literal: true

class AssignmentTeam < Team
  include Analytic::AssignmentTeamAnalytic
  include ReviewAggregator
  # Each AssignmentTeam must belong to a specific assignment
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :review_response_maps, foreign_key: 'reviewee_id'
  has_many :responses, through: :review_response_maps, foreign_key: 'map_id'

  # Delegation to avoid Law of Demeter violations
  delegate :path, to: :assignment, prefix: true

  def hyperlinks
    submitted_hyperlinks.blank? ? [] : YAML.safe_load(submitted_hyperlinks)
  end

  # SubmissionRecords for files this team has submitted against its assignment.
  # Lives on the team (Information Expert) so callers don't have to know about
  # SubmissionRecord's schema.
  def submitted_file_records
    SubmissionRecord.files.where(team_id: id, assignment_id: parent_id).order(created_at: :asc)
  end

  # Submitted content in the simple shape expected by reports: hyperlinks and
  # file paths only. Used by calibration/report views where we just need the
  # URLs.
  def submitted_content
    {
      hyperlinks: hyperlinks,
      files: submitted_file_records.pluck(:content)
    }
  end

  # Submitted content in the rich shape expected by the calibration
  # participants listing (per-file id, name, path, timestamps, submitter).
  def submitted_content_detail
    files = submitted_file_records.map do |record|
      {
        id: record.id,
        name: File.basename(record.content.to_s),
        path: record.content,
        submitted_at: record.created_at,
        submitted_by: record.user
      }
    end

    { hyperlinks: hyperlinks, files: files }
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
  
  # Get the review response map
  def review_map_type
    'ReviewResponseMap'
  end

  def fullname
    name
  end

  # Use current object (AssignmentTeam) as reviewee and create the ReviewResponseMap record
  def assign_reviewer(reviewer)
    assignment = Assignment.find(parent_id)
    raise 'The assignment cannot be found.' if assignment.nil?

    ReviewResponseMap.create(reviewee_id: id, reviewer_id: reviewer.get_reviewer.id, reviewed_object_id: assignment.id, team_reviewing_enabled: assignment.team_reviewing_enabled)
  end

  # Whether the team has submitted work or not
  def has_submissions?
    submitted_files.any? || submitted_hyperlinks.present?
  end

  # Computes the average review grade for an assignment team.
  # This method aggregates scores from all ReviewResponseMaps (i.e., all reviewers of the team).
  def aggregate_review_grade
    compute_average_review_score(review_mappings)
  end
  
  # Adds a participant to this team.
  # - Update the participant's team_id (so their direct reference is consistent)
  # - Ensure there is a TeamsParticipant join record connecting the participant and this team
  def add_participant(participant)
    # need to have a check if the team is full then it can not add participant to the team
    raise TeamFullError, "Team is full." if full?

    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    # participant.update!(team_id: id)

    # Create or reuse the join record to maintain the association
    TeamsParticipant.find_or_create_by!(participant_id: participant.id, team_id: id, user_id: participant.user_id)
  end

  # Removes a participant from this team.
  # - Delete the TeamsParticipant join record
  # - if the participant sent any invitations while being on the team, they all need to be retracted
  # - If the team has no remaining members, destroy the team itself
  def remove_participant(participant)
    # retract all the invitations the participant sent (if any) while being on the this team
    participant.retract_sent_invitations

    # Remove the join record if it exists
    tp = TeamsParticipant.find_by(team_id: id, participant_id: participant.id)
    tp&.destroy
    
    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    # participant.update!(team_id: nil)

    # If no participants remain after removal, delete the team
    destroy if participants.empty?
  end

  # Get the review response map
  def review_map_type
    'ReviewResponseMap'
  end
  
  # Adds a participant to this team.
  # - Update the participant's team_id (so their direct reference is consistent)
  # - Ensure there is a TeamsParticipant join record connecting the participant and this team
  def add_participant(participant)
    # need to have a check if the team is full then it can not add participant to the team
    raise TeamFullError, "Team is full." if full?

    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    # participant.update!(team_id: id)

    # Create or reuse the join record to maintain the association
    TeamsParticipant.find_or_create_by!(participant_id: participant.id, team_id: id, user_id: participant.user_id)
  end
  
  # Removes a participant from this team.
  # - Delete the TeamsParticipant join record
  # - if the participant sent any invitations while being on the team, they all need to be retracted
  # - If the team has no remaining members, destroy the team itself
  def remove_participant(participant)
    # retract all the invitations the participant sent (if any) while being on the this team
    participant.retract_sent_invitations

    # Remove the join record if it exists
    tp = TeamsParticipant.find_by(team_id: id, participant_id: participant.id)
    tp&.destroy
    
    # Update the participant's team_id column - will remove the team reference inside participants table later. keeping it for now
    # participant.update!(team_id: nil)
  end

  # Use current object (AssignmentTeam) as reviewee and create the ReviewResponseMap record
  def assign_reviewer(reviewer)
    assignment = Assignment.find(parent_id)
    raise 'The assignment cannot be found.' if assignment.nil?

    ReviewResponseMap.create(reviewee_id: id, reviewer_id: reviewer.get_reviewer.id, reviewed_object_id: assignment.id, team_reviewing_enabled: assignment.team_reviewing_enabled)
  end

  # Whether the team has submitted work or not
  def has_submissions?
    submitted_files.any? || submitted_hyperlinks.present?
  end

  # Computes the average review grade for an assignment team.
  # This method aggregates scores from all ReviewResponseMaps (i.e., all reviewers of the team).
  def aggregate_review_grade
    compute_average_review_score(review_mappings)
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

class TeamFullError < StandardError; end