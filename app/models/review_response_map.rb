# frozen_string_literal: true
class ReviewResponseMap < ResponseMap
  include ExpertizaConstants::ResponseMapTitles
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false

  scope :for_assignment, ->(assignment_id) { where(reviewed_object_id: assignment_id) }

  # Returns the assignment associated with this review map.
  def reviewer_assignment
    return assignment
  end

  # Backward-compatible alias used by older call sites.
  def response_assignment
    reviewer_assignment
  end

  def questionnaire_type
    'Review'
  end
    
  def get_title
    REVIEW_RESPONSE_MAP_TITLE
  end

  # Get the review response map
  def review_map_type
    'ReviewResponseMap'
  end

  # Returns an array of distinct reviewers (AssignmentParticipant objects) for the given assignment.
  # Reviewers are sorted by their user's full name.
  def self.review_response_report(assignment_id)
    distinct_reviewer_ids = where(reviewed_object_id: assignment_id).distinct.pluck(:reviewer_id)
    reviewers = AssignmentParticipant.where(id: distinct_reviewer_ids, parent_id: assignment_id)
    reviewers.sort_by { |r| r.user&.full_name.to_s.downcase }
  end
end
