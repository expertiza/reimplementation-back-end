# frozen_string_literal: true

module ResponseMapReports
  # Visitor that encapsulates report-building logic for each response map type.
  class ReportVisitor
    # Builds the generic response report payload for an assignment.
    # @param assignment_id [Integer] assignment identifier
    # @return [Hash<Integer, Array<Integer>>|Array<Integer>]
    #   - varying-rubrics assignments: { round_number => [response_ids...] }
    #   - non-varying assignments: [latest_response_id_per_map...]
    def visit_response_map(assignment_id)
      responses = Response.joins(:response_map)
                          .where(response_maps: { reviewed_object_id: assignment_id })
                          .order(created_at: :desc)

      if Assignment.find(assignment_id).varying_rubrics_by_round?
        responses.group_by(&:round)
                 .transform_values { |resps| resps.map(&:id) }
      else
        responses.group_by(&:map_id)
                 .transform_values { |resps| resps.first.id }
                 .values
      end
    end

    # Builds the author-feedback report payload for an assignment.
    # @param assignment_id [Integer] assignment identifier
    # @return [Array]
    #   Payload format:
    #   - index 0: Array<AssignmentParticipant> authors
    #   - indices 1..n: Array<Integer> response IDs
    #     - varying rubrics: one response-id array per round (sorted by round)
    #     - non-varying rubrics: single response-id array of latest response per review map
    def visit_feedback_response_map(assignment_id)
      authors = fetch_authors_for_assignment(assignment_id)
      review_map_ids = ReviewResponseMap.where(reviewed_object_id: assignment_id).pluck(:id)
      review_responses = Response.where(map_id: review_map_ids).order(created_at: :desc)

      if Assignment.find(assignment_id).varying_rubrics_by_round?
        latest_by_map_and_round = {}
        review_responses.each do |response|
          key = [response.map_id, response.round]
          latest_by_map_and_round[key] ||= response
        end

        grouped_by_round = latest_by_map_and_round.values.group_by(&:round).sort.to_h
        response_ids_by_round = grouped_by_round.transform_values { |responses_for_round| responses_for_round.map(&:id) }

        [authors] + response_ids_by_round.values
      else
        latest_by_map = {}
        review_responses.each do |response|
          latest_by_map[response.map_id] ||= response
        end

        [authors, latest_by_map.values.map(&:id)]
      end
    end

    # Builds a review-response report payload for an assignment.
    # @param assignment_id [Integer] assignment identifier
    # @return [Hash<Integer, Array<Integer>>|Array<Integer>]
    #   - varying-rubrics assignments: { round_number => [response_ids...] }
    #   - non-varying assignments: [latest_response_id_per_review_map...]
    def visit_review_response_map(assignment_id)
      review_map_ids = ReviewResponseMap.where(reviewed_object_id: assignment_id).pluck(:id)
      responses = Response.where(map_id: review_map_ids).order(created_at: :desc)

      if Assignment.find(assignment_id).varying_rubrics_by_round?
        responses.group_by(&:round)
                 .transform_values { |resps| resps.map(&:id) }
      else
        responses.group_by(&:map_id)
                 .transform_values { |resps| resps.first.id }
                 .values
      end
    end

    # Builds teammate-review report payload for an assignment.
    # @param assignment_id [Integer] assignment identifier
    # @return [ActiveRecord::Relation<TeammateReviewResponseMap>] distinct reviewer ids
    def visit_teammate_review_response_map(assignment_id)
      TeammateReviewResponseMap.select('DISTINCT reviewer_id').where(reviewed_object_id: assignment_id)
    end

    private

    def fetch_authors_for_assignment(assignment_id)
      Assignment.find(assignment_id).teams.includes(:users).flat_map do |team|
        team.users.map do |user|
          AssignmentParticipant.find_by(parent_id: assignment_id, user_id: user.id)
        end
      end.compact
    end
  end
end
