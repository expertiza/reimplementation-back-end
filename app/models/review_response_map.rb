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

  # Returns the round number of the latest response
  # Used for tracking multiple rounds of review
  # @return [Integer, nil] the round number or nil if no responses
  def round
    self.responses.order(created_at: :desc).first&.round
  end
end
