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
end 