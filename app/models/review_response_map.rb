# frozen_string_literal: true
class ReviewResponseMap < ResponseMap
  include ExpertizaConstants::ResponseMapTitles
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false

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
end
