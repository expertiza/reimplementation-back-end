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

  # Creates a calibration review mapping between a team and an assignment
  # This is used by instructors to review team submissions for calibration purposes
  #
  # @param assignment_id [Integer] The ID of the assignment
  # @param team_id [Integer] The ID of the team to be reviewed
  # @param user_id [Integer] The ID of the user creating the review
  # @return [OpenStruct] An object containing success status and either the review mapping or error message
  def self.create_calibration_review(assignment_id:, team_id:, user_id:)
    # Find the required records
    assignment = Assignment.find(assignment_id)
    team = Team.find(team_id)
    user = User.find(user_id)

    # Check if user has permission to create calibration reviews
    unless user.can_create_calibration_review?(assignment)
      return OpenStruct.new(success?: false, error: 'User does not have permission to create calibration reviews')
    end

    # Check if team has already been assigned for calibration
    if ReviewMapping.exists?(assignment_id: assignment_id, reviewee_id: team.id, review_type: 'Calibration')
      return OpenStruct.new(success?: false, error: 'Team has already been assigned for calibration')
    end

    # Create the calibration review mapping
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