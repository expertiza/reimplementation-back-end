# frozen_string_literal: true

class ReviewResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false

  # returns the assignment related to the response map
  def response_assignment
    return assignment
  end

  # Checks if a reviewer can perform more reviews for an assignment
  # @param assignment_id [Integer] The ID of the assignment to check
  # @param reviewer_id [Integer] The ID of the reviewer to check
  # @return [OpenStruct] Contains success status, allowed boolean, and error message if any
  def self.review_allowed?(assignment_id, reviewer_id)
    # Validate parameters
    if assignment_id.blank? || reviewer_id.blank?
      return OpenStruct.new(
        success: false,
        error: 'Assignment ID and Reviewer ID are required'
      )
    end

    # Find the assignment and reviewer
    assignment = Assignment.find_by(id: assignment_id)
    reviewer = User.find_by(id: reviewer_id)

    # Check if assignment and reviewer exist
    unless assignment && reviewer
      return OpenStruct.new(
        success: false,
        error: 'Assignment or Reviewer not found'
      )
    end

    # Get the number of reviews already assigned to this reviewer
    current_reviews_count = where(
      reviewer_id: reviewer.id,
      reviewed_object_id: assignment.id
    ).count

    # Check if the reviewer has not exceeded the maximum allowed reviews
    allowed = current_reviews_count < assignment.num_reviews_allowed

    # Return structured response
    OpenStruct.new(
      success: true,
      allowed: allowed
    )
  rescue StandardError => e
    OpenStruct.new(
      success: false,
      error: e.message
    )
  end
end
