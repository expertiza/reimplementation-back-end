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

  # Collect the student-submitted calibration responses that share a reviewee
  # with the given instructor calibration map. These are the responses that
  # should be compared against the instructor's review in a calibration
  # report. When a student has revised their review, only the latest
  # submitted response for each map is included.
  def self.peer_calibration_responses_for(instructor_map)
    peer_maps = where(
      reviewed_object_id: instructor_map.reviewed_object_id,
      reviewee_id: instructor_map.reviewee_id,
      for_calibration: true
    ).where.not(id: instructor_map.id)

    peer_maps.filter_map(&:latest_submitted_response)
  end
end
