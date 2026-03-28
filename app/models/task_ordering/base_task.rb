# frozen_string_literal: true

module TaskOrdering
  class BaseTask
    attr_reader :assignment, :team_participant, :review_map

    def initialize(assignment:, team_participant:, review_map: nil)
      @assignment = assignment
      @team_participant = team_participant
      @review_map = review_map
    end

    def participant
      team_participant.participant
    end

    def response_map
      raise NotImplementedError
    end

    def ensure_response_map!
      response_map
    end

    def ensure_response!
      map = response_map
      return if map.nil?

      Response.find_or_create_by!(
        map_id: map.id,
        round: 1
      ) do |resp|
        resp.is_submitted = false
      end
    end

    def completed?
      map = response_map
      return false if map.nil?

      Response.where(map_id: map.id, is_submitted: true).exists?
    end

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
