class ReviewResponseReportIterator
  def initialize(response_maps_with_distinct_participant_id, assignment, type)
    @response_maps_with_distinct_participant_id = response_maps_with_distinct_participant_id
    @assignment = assignment
    @type = type
    @current_reviewer = nil
  end

  def each(&block)
    @response_maps_with_distinct_participant_id.each do |reviewer_id_from_response_map|
      @current_reviewer = reviewer_with_id(@assignment.id, reviewer_id_from_response_map.reviewer_id)
      yield @current_reviewer
    end
  end

  def reviewer_with_id(assignment_id, reviewer_id)
    if assignment.team_reviewing_enabled
      Team.find(reviewer_id)
    else
      Participant.find(reviewer_id)
    end
  end
end