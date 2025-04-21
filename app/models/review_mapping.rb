class ReviewMapping < ApplicationRecord
  # Associations
  # A review mapping belongs to a reviewer (User) who will perform the review
  belongs_to :reviewer, class_name: 'User'
  # A review mapping belongs to a reviewee (User) whose work will be reviewed
  belongs_to :reviewee, class_name: 'User'
  # A review mapping belongs to an assignment
  belongs_to :assignment

  # Validations
  # Ensure all required fields are present
  validates :reviewer_id, presence: true
  validates :reviewee_id, presence: true
  validates :assignment_id, presence: true
  validates :review_type, presence: true

  # Creates a new review mapping between a reviewer and a team
  # Handles the business logic for assigning reviewers to teams
  #
  # @param assignment_id [Integer] The ID of the assignment
  # @param team_id [Integer] The ID of the team to be reviewed
  # @param user_name [String] The name of the user to assign as reviewer
  # @return [OpenStruct] An object containing success status and either the review mapping or error message
  def self.add_reviewer(assignment_id:, team_id:, user_name:)
    # Find the required records
    assignment = Assignment.find(assignment_id)
    team = Team.find(team_id)
    user = User.find_by(name: user_name)

    # Validate user exists
    unless user
      return OpenStruct.new(success?: false, error: "User '#{user_name}' not found")
    end

    # Validate user is a participant in the assignment
    participant = Participant.find_by(user_id: user.id, assignment_id: assignment.id)
    unless participant
      return OpenStruct.new(success?: false, error: "User '#{user_name}' is not a participant in this assignment")
    end

    # Validate user can review
    unless participant.can_review?
      return OpenStruct.new(success?: false, error: "User '#{user_name}' cannot review in this assignment")
    end

    # Find a user from the team to be the reviewee
    team_user = TeamsUser.find_by(team_id: team.id)
    unless team_user
      return OpenStruct.new(success?: false, error: "No users found in team #{team_id}")
    end
    reviewee = User.find(team_user.user_id)

    # Check if user is already assigned to review this team
    if ReviewMapping.exists?(reviewer_id: user.id, reviewee_id: reviewee.id, assignment_id: assignment.id)
      return OpenStruct.new(success?: false, error: "User '#{user_name}' is already assigned to review this team")
    end

    # Create the review mapping
    review_mapping = ReviewMapping.create!(
      reviewer_id: user.id,
      reviewee_id: reviewee.id,
      assignment_id: assignment.id,
      review_type: 'Review'
    )

    OpenStruct.new(success?: true, review_mapping: review_mapping)
  end

  # Creates a calibration review mapping between a team and an assignment
  # This is used by instructors to review team submissions for calibration purposes
  #
  # @param assignment_id [Integer] The ID of the assignment
  # @param team_id [Integer] The ID of the team to be reviewed
  # @param user_id [Integer] The ID of the user creating the review
  # @return [OpenStruct] An object containing success status and either the review mapping or error message
  def self.create_calibration_review(assignment_id:, team_id:, user_id:)
    assignment = Assignment.find(assignment_id)
    team = Team.find(team_id)
    user = User.find(user_id)

    unless user.can_create_calibration_review?(assignment)
      return OpenStruct.new(success?: false, error: 'User does not have permission to create calibration reviews')
    end

    # Find a user from the team to be the reviewee
    team_user = TeamsUser.find_by(team_id: team.id)
    unless team_user
      return OpenStruct.new(success?: false, error: "No users found in team #{team_id}")
    end
    reviewee = User.find(team_user.user_id)

    # Check if a calibration review already exists for this team
    if ReviewMapping.exists?(assignment_id: assignment_id, reviewee_id: reviewee.id, review_type: 'Calibration')
      return OpenStruct.new(success?: false, error: 'Team has already been assigned for calibration')
    end

    review_mapping = ReviewMapping.new(
      reviewer_id: user_id,
      reviewee_id: reviewee.id,
      assignment_id: assignment_id,
      review_type: 'Calibration'
    )

    if review_mapping.save
      OpenStruct.new(success?: true, review_mapping: review_mapping)
    else
      OpenStruct.new(success?: false, error: review_mapping.errors.full_messages.join(', '))
    end
  end

  # Assigns a reviewer dynamically to a team or topic
  #
  # @param assignment_id [Integer] The ID of the assignment
  # @param reviewer_id [Integer] The ID of the reviewer
  # @param topic_id [Integer] The ID of the topic (optional)
  # @param i_dont_care [Boolean] Whether the reviewer doesn't care about topic selection
  # @return [OpenStruct] An object containing success status and either the review mapping or error message
  def self.assign_reviewer_dynamically(assignment_id:, reviewer_id:, topic_id: nil, i_dont_care: false)
    assignment = Assignment.find(assignment_id)
    participant = Participant.find_by(user_id: reviewer_id, assignment_id: assignment.id)
    reviewer = User.find(reviewer_id)

    return OpenStruct.new(success?: false, error: 'Reviewer not found') unless reviewer

    # Validate review limits
    unless can_review?(assignment, reviewer)
      return OpenStruct.new(success?: false, error: "You cannot do more than #{assignment.num_reviews_allowed} reviews based on assignment policy")
    end

    # Check outstanding reviews
    if has_outstanding_reviews?(assignment, reviewer)
      return OpenStruct.new(success?: false, error: "You cannot do more reviews when you have #{Assignment::MAX_OUTSTANDING_REVIEWS} reviews to do")
    end

    # Handle topic-based assignments
    if assignment.topics?
      return handle_topic_based_assignment(assignment, reviewer, topic_id, i_dont_care)
    else
      return handle_non_topic_assignment(assignment, reviewer)
    end
  end

  # Checks if a reviewer has exceeded the maximum number of outstanding (incomplete) reviews
  # for a given assignment.
  #
  # @param assignment [Assignment] The assignment to check reviews for
  # @param reviewer [User] The reviewer to check
  # @return [OpenStruct] An object containing:
  #   - success [Boolean] Whether the check was successful
  #   - allowed [Boolean] Whether the reviewer can perform more reviews
  #   - error [String] Error message if any
  def self.check_outstanding_reviews?(assignment, reviewer)
    # Find all review response maps for this assignment and reviewer
    review_mappings = ReviewResponseMap.where(reviewed_object_id: assignment.id, reviewer_id: reviewer.id)
    
    # Count completed reviews (where response exists)
    completed_reviews = review_mappings.joins(:response).count
    
    # Count total assigned reviews
    total_reviews = review_mappings.count
    
    # Calculate outstanding reviews
    outstanding_reviews = total_reviews - completed_reviews
    
    # Get the maximum allowed outstanding reviews (default to 2 if not set)
    max_outstanding = 2
    
    OpenStruct.new(
      success: true,
      allowed: outstanding_reviews < max_outstanding,
      error: outstanding_reviews >= max_outstanding ? 
        "You cannot do more reviews when you have #{outstanding_reviews} reviews to do" : nil
    )
  rescue StandardError => e
    OpenStruct.new(
      success: false,
      allowed: false,
      error: "Error checking outstanding reviews: #{e.message}"
    )
  end

  private_class_method

  # Checks if the reviewer can perform more reviews based on assignment policy
  def self.can_review?(assignment, reviewer)
    current_reviews = where(reviewer_id: reviewer.id, assignment_id: assignment.id).count
    # If num_reviews_allowed is nil, use the default value from the Assignment model
    max_reviews = assignment.num_reviews_allowed || 3
    current_reviews < max_reviews
  end

  # Checks if the reviewer has outstanding reviews
  def self.has_outstanding_reviews?(assignment, reviewer)
    return false if assignment.nil?
    return false if reviewer.nil?

    # Find all review mappings for this assignment and reviewer
    review_mappings = where(reviewer_id: reviewer.id, assignment_id: assignment.id)
    return false if review_mappings.empty?

    # Count completed reviews (where response exists)
    completed_reviews = review_mappings.joins(:response).count
    
    # Count total reviews
    total_reviews = review_mappings.count
    
    # Calculate outstanding reviews
    outstanding_reviews = total_reviews - completed_reviews

    outstanding_reviews >= Assignment::MAX_OUTSTANDING_REVIEWS
  end

  # Handles assignment with topics
  def self.handle_topic_based_assignment(assignment, reviewer, topic_id, i_dont_care)
    unless i_dont_care || topic_id || !assignment.can_choose_topic_to_review?
      return OpenStruct.new(success?: false, error: 'No topic is selected. Please go back and select a topic.')
    end

    topic = if topic_id
              SignUpTopic.find(topic_id)
            else
              assignment.candidate_topics_to_review(reviewer).to_a.sample
            end

    if topic.nil?
      OpenStruct.new(success?: false, error: 'No topics are available to review at this time. Please try later.')
    else
      create_review_mapping(assignment, reviewer, topic)
    end
  end

  # Handles assignment without topics
  def self.handle_non_topic_assignment(assignment, reviewer)
    assignment_teams = assignment.candidate_assignment_teams_to_review(reviewer)
    assignment_team = assignment_teams.to_a.sample

    if assignment_team.nil?
      OpenStruct.new(success?: false, error: 'No artifacts are available to review at this time. Please try later.')
    else
      create_review_mapping_no_topic(assignment, reviewer, assignment_team)
    end
  end

  # Creates a review mapping for topic-based assignments
  def self.create_review_mapping(assignment, reviewer, topic)
    # Find the team signed up for this topic
    signed_up_team = SignedUpTeam.find_by(sign_up_topic_id: topic.id)
    return OpenStruct.new(success?: false, error: 'No team signed up for this topic') unless signed_up_team

    # Find a user from the team
    team_user = TeamsUser.find_by(team_id: signed_up_team.team_id)
    return OpenStruct.new(success?: false, error: 'No users found in team') unless team_user

    reviewee = User.find(team_user.user_id)

    review_mapping = ReviewMapping.create!(
      reviewer_id: reviewer.id,
      reviewee_id: reviewee.id,
      assignment_id: assignment.id,
      review_type: 'Review'
    )
    OpenStruct.new(success?: true, review_mapping: review_mapping)
  rescue StandardError => e
    OpenStruct.new(success?: false, error: e.message)
  end

  # Creates a review mapping for non-topic assignments
  def self.create_review_mapping_no_topic(assignment, reviewer, assignment_team)
    # Find a user from the team
    team_user = TeamsUser.find_by(team_id: assignment_team.id)
    return OpenStruct.new(success?: false, error: 'No users found in team') unless team_user

    reviewee = User.find(team_user.user_id)

    review_mapping = ReviewMapping.create!(
      reviewer_id: reviewer.id,
      reviewee_id: reviewee.id,
      assignment_id: assignment.id,
      review_type: 'Review'
    )
    OpenStruct.new(success?: true, review_mapping: review_mapping)
  rescue StandardError => e
    OpenStruct.new(success?: false, error: e.message)
  end
end 