module TaskOrdering
  class BaseTask
    attr_reader :assignment, :team_participant, :review_map

    def initialize(assignment:, team_participant:, review_map: nil)
      @assignment = assignment
      @team_participant = team_participant
      @review_map = review_map
    end

    # Must be implemented by subclasses
    def response_map
      raise NotImplementedError
    end

    def ensure_response_map!
      response_map
    end

    # Create response if none exists
    def ensure_response!
      map = response_map
      return if map.nil?

      Response.find_or_create_by!(
        map_id: map.id
      ) do |resp|
        resp.is_submitted = false
      end
    end

    def completed?
      map = response_map
      return false if map.nil?

      Response.where(map_id: map.id, is_submitted: true).exists?
    end

    # Structure returned to controller
    def to_task_hash
      map = response_map
      {
        task_type: task_type,
        assignment_id: assignment.id,
        response_map_id: map&.id,
        response_map_type: map&.type,
        reviewee_id: map&.reviewee_id,
        team_participant_id: team_participant.id
      }
    end
  end
end