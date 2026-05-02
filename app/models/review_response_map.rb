# frozen_string_literal: true
class ReviewResponseMap < ResponseMap
  include ResponseMapSubclassTitles
  belongs_to :reviewee, class_name: 'Team', foreign_key: 'reviewee_id', inverse_of: false

  # All for_calibration maps on a given assignment.
  # Centralises the for_calibration condition so callers don't repeat it.
  scope :calibration_for, ->(assignment) {
    where(reviewed_object_id: assignment.id, for_calibration: true)
  }

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

  # Iterator over the latest submitted peer calibration Response for each
  # student calibration map that shares the same reviewee as `instructor_map`.
  #
  # Uses find_each (batch loading) so large calibration cohorts don't load
  # all maps into memory at once. Yields one Response at a time.
  #
  # Without a block, returns an Enumerator so callers can chain lazily.
  def self.peer_calibration_responses_each(instructor_map)
    return enum_for(:peer_calibration_responses_each, instructor_map) unless block_given?

    peer_maps = where(
      reviewed_object_id: instructor_map.reviewed_object_id,
      reviewee_id:        instructor_map.reviewee_id,
      for_calibration:    true
    ).where.not(id: instructor_map.id)

    peer_maps.find_each do |map|
      response = map.latest_submitted_response
      yield response if response
    end
  end

  # Serializes this calibration map into the JSON row expected by the
  # assignment editor's Calibration tab.
  # Lives here (Information Expert) — the map knows its reviewee team,
  # its reviewer, and can ask itself for review_status.
  def calibration_participant_json(instructor_user_id:)
    team      = reviewee
    submitter = team.participants.where(type: 'AssignmentParticipant').first
    return nil unless submitter

    {
      participant_id:           submitter.id,
      user_id:                  submitter.user_id,
      username:                 submitter.user&.name,
      full_name:                submitter.user&.full_name,
      handle:                   submitter.handle,
      team_id:                  team.id,
      team_name:                team.name,
      instructor_review_map_id: id,
      instructor_review_status: review_status,
      submissions:              team.submitted_content_detail
    }
  end
end
