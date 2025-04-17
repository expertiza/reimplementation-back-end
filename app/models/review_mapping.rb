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
  # @param topic_id [Integer] The ID of the topic (optional)
  # @return [OpenStruct] An object containing success status and either the review mapping or error message
  def self.add_reviewer(assignment_id:, team_id:, user_name:, topic_id: nil)
    # Find the required records
    assignment = Assignment.find(assignment_id)
    team = Team.find(team_id)
    user = User.find_by(name: user_name)

    # Validate user exists
    unless user
      return OpenStruct.new(success?: false, error: "User '#{user_name}' not found")
    end

    # Check for self-review
    if TeamsUser.exists?(team_id: team_id, user_id: user.id)
      return OpenStruct.new(success?: false, error: 'You cannot assign this student to review their own artifact')
    end

    # Sign up the user for the topic if provided
    if topic_id
      SignUpSheet.signup_team(assignment_id, user.id, topic_id)
    end

    # Get or create the reviewer participant
    reviewer = assignment.participants.find_or_create_by(user_id: user.id)

    # Check for existing review mapping
    if ReviewMapping.exists?(reviewee_id: team_id, reviewer_id: reviewer.id, assignment_id: assignment_id)
      return OpenStruct.new(success?: false, error: "The reviewer, '#{user.name}', is already assigned to this contributor")
    end

    # Create the review mapping
    review_mapping = ReviewMapping.new(
      reviewer_id: reviewer.id,
      reviewee_id: team_id,
      assignment_id: assignment_id,
      review_type: 'Review'
    )

    if review_mapping.save
      OpenStruct.new(success?: true, review_mapping: review_mapping)
    else
      OpenStruct.new(success?: false, error: review_mapping.errors.full_messages.join(', '))
    end
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

    if ReviewMapping.exists?(assignment_id: assignment_id, reviewee_id: team.id, review_type: 'Calibration')
      return OpenStruct.new(success?: false, error: 'Team has already been assigned for calibration')
    end

    review_mapping = ReviewMapping.new(
      reviewer_id: user_id,
      reviewee_id: team.id,
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
    participant = AssignmentParticipant.find_by(user_id: reviewer_id, parent_id: assignment.id)
    reviewer = participant&.get_reviewer

    return OpenStruct.new(success?: false, error: 'Reviewer not found') unless reviewer

    # Validate review limits
    unless can_review?(assignment, reviewer)
      return OpenStruct.new(success?: false, error: "You cannot do more than #{assignment.num_reviews_allowed} reviews based on assignment policy")
    end

    # Check outstanding reviews
    if has_outstanding_reviews?(assignment, reviewer)
      return OpenStruct.new(success?: false, error: "You cannot do more reviews when you have #{Assignment.max_outstanding_reviews} reviews to do")
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
    # Find all review mappings for this assignment and reviewer
    review_mappings = where(reviewed_object_id: assignment.id, reviewer_id: reviewer.id)
    
    # Count completed reviews (where response exists)
    completed_reviews = review_mappings.joins(:response).count
    
    # Count total assigned reviews
    total_reviews = review_mappings.count
    
    # Calculate outstanding reviews
    outstanding_reviews = total_reviews - completed_reviews
    
    # Get the maximum allowed outstanding reviews from assignment policy
    max_outstanding = assignment.max_outstanding_reviews || 2
    
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
    current_reviews < assignment.num_reviews_allowed
  end

  # Checks if the reviewer has outstanding reviews
  def self.has_outstanding_reviews?(assignment, reviewer)
    outstanding_reviews = where(
      reviewer_id: reviewer.id,
      assignment_id: assignment.id,
      status: 'pending'
    ).count
    outstanding_reviews >= Assignment.max_outstanding_reviews
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
    review_mapping = assignment.assign_reviewer_dynamically(reviewer, topic)
    if review_mapping
      OpenStruct.new(success?: true, review_mapping: review_mapping)
    else
      OpenStruct.new(success?: false, error: 'Failed to create review mapping')
    end
  end

  # Creates a review mapping for non-topic assignments
  def self.create_review_mapping_no_topic(assignment, reviewer, assignment_team)
    review_mapping = assignment.assign_reviewer_dynamically_no_topic(reviewer, assignment_team)
    if review_mapping
      OpenStruct.new(success?: true, review_mapping: review_mapping)
    else
      OpenStruct.new(success?: false, error: 'Failed to create review mapping')
    end
  end
end 