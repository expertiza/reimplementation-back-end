# frozen_string_literal: true

class ReviewResponseMap < ResponseMap
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false

  # returns the assignment related to the response map
  def response_assignment
    return assignment
  end

  # Returns all assessments (responses) for the given reviewee
  def self.assessments_for(reviewee)
    where(reviewee_id: reviewee.id).includes(:response).map(&:response).flatten
  end
end
