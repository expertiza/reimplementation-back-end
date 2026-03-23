# frozen_string_literal: true
class ReviewResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false

  # returns the assignment related to the response map
  def response_assignment
    return assignment
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

  # Accepts a report visitor for double-dispatch report generation.
  # Builds a review-response report payload for an assignment.
  # @param assignment_id [Integer] assignment identifier
  # @return [Hash<Integer, Array<Integer>>|Array<Integer>]
  #   - varying-rubrics assignments: { round_number => [response_ids...] }
  #   - non-varying assignments: [latest_response_id_per_review_map...]
  def self.accept_report_visitor(visitor, assignment_id)
    visitor.visit_review_response_map(assignment_id)
  end
end
