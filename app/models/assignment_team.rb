class AssignmentTeam < Team
  # require File.dirname(__FILE__) + '/analytic/assignment_team_analytic'
  # include AssignmentTeamAnalytic
  # include Scoring
  
  belongs_to :assignment, class_name: 'Assignment', foreign_key: 'parent_id'
  has_many :review_mappings, class_name: 'ReviewResponseMap', foreign_key: 'reviewee_id'
  has_many :review_response_maps, foreign_key: 'reviewee_id'
  has_many :responses, through: :review_response_maps, foreign_key: 'map_id'

  # E2516: Fetches the user_id of the first member of the team.
  # If the current_user is part of the team, return their id.
  # @param [User] current_user - The user currently logged in (optional)
  # @return [Integer] user_id of the team member
  def user_id(current_user = nil)
    return current_user.id if current_user.present? && users.include?(current_user)
    users.first.id
  end

  # E2516: Checks if a given participant is part of the team.
  # @param [Participant] participant - The participant to check
  # @return [Boolean] true if the participant is in the team, false otherwise
  def includes?(participant)
    participants.include?(participant)
  end

  # E2516: Returns the parent model name (Assignment) for the current team.
  # @return [String] Parent model name
  def parent_model
    'Assignment'
  end

  # E2516: Assigns a reviewer to this team.
  # Calls `create_review_map` to generate a ReviewResponseMap.
  # @param [Reviewer] reviewer - The reviewer to be assigned
  def assign_reviewer(reviewer)
    assignment = Assignment.find_by(id: parent_id)
    raise 'The assignment cannot be found.' if assignment.nil?

    # E2516: Create a ReviewResponseMap for this reviewer
    create_review_map(reviewer, assignment)
  end

  # E2516: Creates and returns a review map.
  # Extracted to avoid duplicate code in `assign_reviewer`.
  # @param [Reviewer] reviewer - The reviewer to assign
  # @param [Assignment] assignment - The assignment being reviewed
  # @return [ReviewResponseMap] The created review map
  def create_review_map(reviewer, assignment)
    ReviewResponseMap.create!(
      reviewee_id: id,
      reviewer_id: reviewer.get_reviewer.id,
      reviewed_object_id: assignment.id,
      team_reviewing_enabled: assignment.team_reviewing_enabled
    )
  end

  # E2516: Checks if a review has been done by a given reviewer.
  # @param [Reviewer] reviewer - The reviewer to check
  # @return [Boolean] true if reviewed, false otherwise
  def reviewed_by?(reviewer)
    ReviewResponseMap.exists?(reviewee_id: id, reviewer_id: reviewer.get_reviewer.id, reviewed_object_id: assignment.id)
  end

  # E2516: Fetches the participants associated with the team.
  # Delegates this to TeamsParticipant to promote DRY principles.
  # @return [Array] Array of participants
  def participants
    TeamsParticipant.team_members(id)
  end

  # E2516: Adds a participant to the team via TeamsParticipant.
  # @param [Integer] assignment_id - The assignment id
  # @param [User] user - The user to be added as a participant
  def add_participant(assignment_id, user)
    return if TeamsParticipant.exists?(participant_id: user.id, team_id: id)

    TeamsParticipant.create!(participant_id: user.id, team_id: id)
  end

  # E2516: Creates a new team and associates a user and topic.
  # Extracted to simplify `create_new_team` and reduce nesting.
  # @param [Integer] user_id - ID of the user
  # @param [SignUpTopic] signuptopic - The selected topic
  def create_new_team(user_id, signuptopic)
    t_user = TeamsUser.create!(team_id: id, user_id: user_id)
    SignedUpTeam.create!(topic_id: signuptopic.id, team_id: id, is_waitlisted: 0)
    parent = TeamNode.create!(parent_id: signuptopic.assignment_id, node_object_id: id)
    TeamUserNode.create!(parent_id: parent.id, node_object_id: t_user.id)
  end

  # E2516: Submits a hyperlink to the team's submission.
  # Moved to TeamFileService for better separation of concerns.
  # @param [String] hyperlink - The URL to submit
  def submit_hyperlink(hyperlink)
    TeamFileService.submit_hyperlink(self, hyperlink)
  end

  # E2516: Removes a hyperlink from the team's submission.
  # Moved to TeamFileService for consistency.
  # @param [String] hyperlink_to_delete - The URL to remove
  def remove_hyperlink(hyperlink_to_delete)
    TeamFileService.remove_hyperlink(self, hyperlink_to_delete)
  end

  # E2516: Checks if the team has submitted any files or hyperlinks.
  # @return [Boolean] true if submissions exist, false otherwise
  def has_submissions?
    submitted_files.any? || submitted_hyperlinks.present?
  end

  # E2516: Returns the most recent submission by the team.
  # Optimized query with order to fetch the latest submission.
  # @return [SubmissionRecord] The most recent submission
  def most_recent_submission
    SubmissionRecord.where(team_id: id, assignment_id: parent_id).order(updated_at: :desc).first
  end
end
